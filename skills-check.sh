#!/usr/bin/env bash
# Check vendored skills against their upstream sources.
#   ./skills-check.sh [check]
#
# Sources live in .agents/skills-sources.tsv. The folder hash follows the skills
# CLI algorithm (vercel-labs/skills README, "Lock File Content Hash"), so a
# recorded hash matches what `npx skills` would compute for the same folder.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$DOTFILES_DIR/.agents/skills-sources.tsv"
SKILLS_DIR="$DOTFILES_DIR/.agents/skills"

usage() {
  cat <<EOF
Usage:
  $0 check

check  Compare every skill in .agents/skills-sources.tsv with its upstream repo
EOF
  exit 1
}

hash_dir() {
  node - "$1" <<'NODE'
const { createHash } = require("node:crypto");
const { readdirSync, readFileSync, statSync, realpathSync } = require("node:fs");
const { join, relative, sep } = require("node:path");

const SKIP_DIRS = new Set([".git", "__pycache__", ".pypackages__"]);
const SKIP_FILES = new Set(["metadata.json"]);
const root = realpathSync(process.argv[2]);
const rootPrefix = root + sep;
const files = [];

function walk(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const abs = join(dir, entry.name);
    let isDir = entry.isDirectory();
    let isFile = entry.isFile();
    if (entry.isSymbolicLink()) {
      try {
        const target = realpathSync(abs);
        if (!target.startsWith(rootPrefix)) continue;
        const st = statSync(target);
        isDir = st.isDirectory();
        isFile = st.isFile();
      } catch {
        continue;
      }
    }
    if (isDir) {
      if (!SKIP_DIRS.has(entry.name)) walk(abs);
    } else if (isFile) {
      if (!SKIP_FILES.has(entry.name)) files.push(relative(root, abs).split(sep).join("/"));
    }
  }
}

walk(root);

const entries = files
  .map((path) => {
    let buf = readFileSync(join(root, path));
    if (!buf.includes(0)) buf = Buffer.from(buf.toString("utf8").replace(/\r\n/g, "\n"), "utf8");
    return { path, buf };
  })
  .sort((a, b) => Buffer.compare(Buffer.from(a.path, "utf8"), Buffer.from(b.path, "utf8")));

const hash = createHash("sha256");
for (const { path, buf } of entries) {
  hash.update(Buffer.from(path, "utf8"));
  hash.update(Buffer.from([0]));
  hash.update(Buffer.from(String(buf.length), "ascii"));
  hash.update(Buffer.from([0]));
  hash.update(buf);
}
process.stdout.write(hash.digest("hex"));
NODE
}

[ "${1:-check}" = "check" ] || usage
[ -f "$MANIFEST" ] || { echo "error: missing $MANIFEST" >&2; exit 1; }
command -v node >/dev/null || { echo "error: node not found (needed for the folder hash)" >&2; exit 1; }

skills=(); repos=(); paths=(); adopted=(); recorded=()
while IFS=$'\t' read -r skill repo path ac ah; do
  case "$skill" in ''|'#'*) continue ;; esac
  skills+=("$skill"); repos+=("$repo"); paths+=("$path")
  adopted+=("${ac:-}"); recorded+=("${ah:-}")
done < "$MANIFEST"
[ "${#skills[@]}" -gt 0 ] || { echo "error: no rows in $MANIFEST" >&2; exit 1; }

tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/skills-check.XXXXXX")
trap 'rm -rf "$tmp_root"' EXIT

repo_dir() {
  local repo="$1" dest="$tmp_root/${repo//\//_}"
  if [ ! -d "$dest" ]; then
    git clone --depth 1 --filter=blob:none --sparse --quiet \
      "https://github.com/$repo.git" "$dest" >&2 || return 1
  fi
  printf '%s' "$dest"
}

# Fetch only the paths this manifest needs from each repo.
for repo in $(printf '%s\n' "${repos[@]}" | sort -u); do
  dest=$(repo_dir "$repo") || { echo "error: clone failed for $repo" >&2; exit 1; }
  set_paths=()
  for i in "${!repos[@]}"; do
    [ "${repos[$i]}" = "$repo" ] && set_paths+=("${paths[$i]}")
  done
  if ! git -C "$dest" sparse-checkout set "${set_paths[@]}" >/dev/null 2>&1; then
    echo "error: sparse checkout failed for $repo" >&2
    exit 1
  fi
  # Depth 200 keeps `log -- <path>` meaningful for the last-change column.
  git -C "$dest" fetch --deepen=200 --quiet origin HEAD >/dev/null 2>&1 || true
done

count_current=0 count_behind=0 count_edited=0 count_unknown=0
rows=()
for i in "${!skills[@]}"; do
  skill="${skills[$i]}" repo="${repos[$i]}" path="${paths[$i]}"
  ac="${adopted[$i]}" ah="${recorded[$i]}"
  local_dir="$SKILLS_DIR/$skill"

  if [ ! -d "$local_dir" ]; then
    rows+=("$skill|missing|skill folder not in .agents/skills")
    continue
  fi

  dest="$tmp_root/${repo//\//_}"
  local_hash=$(hash_dir "$local_dir")
  upstream_hash=$(hash_dir "$dest/$path")
  upstream_date=$(git -C "$dest" log -1 --format=%cs -- "$path" 2>/dev/null || true)

  if [ "$local_hash" = "$upstream_hash" ]; then
    rows+=("$skill|current|-")
    count_current=$((count_current + 1))
    continue
  fi

  if [ -z "$ah" ]; then
    rows+=("$skill|unknown-baseline|no adoption point; upstream last change ${upstream_date:--}")
    count_unknown=$((count_unknown + 1))
    continue
  fi

  changed=""
  if [ "$ah" != "$upstream_hash" ]; then
    if [ -n "$ac" ] && ! git -C "$dest" cat-file -e "${ac}^{commit}" 2>/dev/null; then
      git -C "$dest" fetch --depth 1 --quiet origin "$ac" >/dev/null 2>&1 || true
    fi
    changed=$(git -C "$dest" diff --name-only "$ac" HEAD -- "$path" 2>/dev/null |
      sed "s|^$path/||" | paste -sd, - || true)
    # Long lists swamp the table: keep the first few and count the rest.
    n_changed=$(printf '%s' "$changed" | awk -F, '{print NF}')
    if [ "${n_changed:-0}" -gt 4 ]; then
      changed="$(printf '%s' "$changed" | cut -d, -f1-3) (+$((n_changed - 3)) more)"
    fi
  fi

  if [ "$local_hash" = "$ah" ]; then
    rows+=("$skill|behind|${changed:-upstream last change ${upstream_date:--}}")
    count_behind=$((count_behind + 1))
  elif [ "$changed" = "" ]; then
    rows+=("$skill|edited|local files differ from upstream")
    count_edited=$((count_edited + 1))
  else
    rows+=("$skill|behind + edited|$changed")
    count_edited=$((count_edited + 1))
  fi
done

printf '%-36s %-18s %s\n' "skill" "status" "detail"
printf '%-36s %-18s %s\n' "-----" "------" "------"
for row in "${rows[@]}"; do
  IFS='|' read -r skill status detail <<<"$row"
  printf '%-36s %-18s %s\n' "$skill" "$status" "${detail:--}"
done

printf '\n%s checked: %s current, %s behind, %s edited, %s unknown baseline\n' \
  "${#rows[@]}" "$count_current" "$count_behind" "$count_edited" "$count_unknown"
