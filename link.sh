#!/usr/bin/env bash
# Manage dotfile symlinks via symlinks.txt
#   ./link.sh link  <home-path>     adopt into repo, symlink back, append list
#   ./link.sh sync  [name]          apply list for this OS (all, or matching name)

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FILE="$DOTFILES_DIR/symlinks.txt"

usage() {
  cat <<EOF
Usage:
  $0 link <home-path>
  $0 sync [name]

link  Move <home-path> into the repo (basename), symlink back, append symlinks.txt
sync  Create symlinks/copies from symlinks.txt for this OS (optional name filter)
EOF
  exit 1
}

detect_os() {
  case "$(uname -s)" in
    Darwin) echo mac ;;
    Linux) echo linux ;;
    MINGW*|MSYS*|CYGWIN*) echo win ;;
    *) echo unknown ;;
  esac
}

# Sets DEST_TAG (may be empty) and DEST_PATH from a raw destination field
parse_dest() {
  local raw="$1"
  if [[ "$raw" == mac:* || "$raw" == linux:* || "$raw" == win:* ]]; then
    DEST_TAG="${raw%%:*}"
    DEST_PATH="${raw#*:}"
  else
    DEST_TAG=""
    DEST_PATH="$raw"
  fi
}

expand_dest() {
  local d="$1"
  local var val
  while [[ "$d" =~ %([A-Za-z0-9_]+)% ]]; do
    var="${BASH_REMATCH[1]}"
    # bash 3-safe indirect expand
    eval "val=\"\${$var-}\""
    if [[ -z "$val" ]]; then
      echo "error: env %$var% is empty (needed for $d)" >&2
      return 1
    fi
    d="${d//%$var%/$val}"
  done
  if [[ "$d" == "~" || "$d" == "~/"* ]]; then
    d="${HOME}${d:1}"
  fi
  printf '%s\n' "$d"
}

home_form() {
  local p="$1"
  if [[ "$p" == "$HOME" || "$p" == "$HOME"/* ]]; then
    printf '~%s\n' "${p#"$HOME"}"
  else
    printf '%s\n' "$p"
  fi
}

ask_overwrite() {
  local path="$1"
  local reply
  read -r -p "Replace $path? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

same_link() {
  local dest="$1" target="$2"
  [[ -L "$dest" ]] && [[ "$(readlink "$dest")" == "$target" ]]
}

ensure_parent() {
  mkdir -p "$(dirname "$1")"
}

do_symlink() {
  local repo_rel="$1" dest_raw="$2"
  local src dest

  src="$DOTFILES_DIR/$repo_rel"
  if [[ ! -e "$src" ]]; then
    echo "skip link $repo_rel: missing in repo" >&2
    return 0
  fi

  dest="$(expand_dest "$dest_raw")"

  if same_link "$dest" "$src"; then
    echo "ok  $dest"
    return 0
  fi

  if [[ -L "$dest" ]]; then
    echo "replace symlink $dest"
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    if ! ask_overwrite "$dest"; then
      echo "skip $dest"
      return 0
    fi
    rm -rf "$dest"
  fi

  ensure_parent "$dest"
  ln -s "$src" "$dest"
  echo "link $dest -> $src"
}

do_copy() {
  local repo_rel="$1" dest_raw="$2"
  local src dest

  src="$DOTFILES_DIR/$repo_rel"
  if [[ ! -e "$src" ]]; then
    echo "skip copy $repo_rel: missing in repo" >&2
    return 0
  fi

  dest="$(expand_dest "$dest_raw")"
  if [[ -e "$dest" ]]; then
    echo "ok  $dest (exists, copy skipped)"
    return 0
  fi

  ensure_parent "$dest"
  cp -R "$src" "$dest"
  echo "copy $src -> $dest"
}

# Print: kind<TAB>repo<TAB>rest
list_entries() {
  local line kind rest repo dest name msg
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line#"${line%%[![:space:]]*}"}"
    [[ -z "$line" || "$line" == \#* ]] && continue
    kind="${line%% *}"
    rest="${line#"$kind"}"
    rest="${rest#"${rest%%[![:space:]]*}"}"
    case "$kind" in
      link|copy)
        repo="${rest%% *}"
        dest="${rest#"$repo"}"
        dest="${dest#"${dest%%[![:space:]]*}"}"
        printf '%s\t%s\t%s\n' "$kind" "$repo" "$dest"
        ;;
      note)
        name="${rest%% *}"
        msg="${rest#"$name"}"
        msg="${msg#"${msg%%[![:space:]]*}"}"
        printf '%s\t%s\t%s\n' "$kind" "$name" "$msg"
        ;;
      *)
        echo "warning: unknown kind in symlinks.txt: $line" >&2
        ;;
    esac
  done < "$LIST_FILE"
}

name_matches() {
  local filter="$1" repo="$2"
  [[ -z "$filter" ]] && return 0
  [[ "$repo" == "$filter" ]] && return 0
  [[ "$(basename "$repo")" == "$filter" ]] && return 0
  return 1
}

# Space-delimited repo names that have a tagged line for this OS
repos_preferring_os() {
  local os="$1" filter="$2"
  local kind repo raw out=""
  while IFS=$'\t' read -r kind repo raw; do
    [[ "$kind" == link || "$kind" == copy ]] || continue
    name_matches "$filter" "$repo" || continue
    parse_dest "$raw"
    if [[ "$DEST_TAG" == "$os" ]]; then
      out="$out $repo "
    fi
  done < <(list_entries)
  printf '%s\n' "$out"
}

cmd_sync() {
  local filter="${1:-}"
  local os kind repo raw prefer

  os="$(detect_os)"
  if [[ ! -f "$LIST_FILE" ]]; then
    echo "error: missing $LIST_FILE" >&2
    exit 1
  fi

  prefer="$(repos_preferring_os "$os" "$filter")"

  while IFS=$'\t' read -r kind repo raw; do
    name_matches "$filter" "$repo" || continue

    case "$kind" in
      note)
        echo "note [$repo] $raw"
        ;;
      link|copy)
        parse_dest "$raw"
        if [[ -n "$DEST_TAG" && "$DEST_TAG" != "$os" ]]; then
          continue
        fi
        if [[ -z "$DEST_TAG" && " $prefer " == *" $repo "* ]]; then
          continue
        fi
        if [[ "$kind" == link ]]; then
          do_symlink "$repo" "$DEST_PATH"
        else
          do_copy "$repo" "$DEST_PATH"
        fi
        ;;
    esac
  done < <(list_entries)
}

cmd_link() {
  local home_path repo_name target list_dest

  if [[ -z "${1:-}" ]]; then
    usage
  fi

  home_path="$1"
  if [[ "$home_path" == "~"* ]]; then
    home_path="${HOME}${home_path:1}"
  fi
  if [[ "$home_path" != /* ]]; then
    home_path="$(cd "$(dirname "$home_path")" && pwd)/$(basename "$home_path")"
  fi

  if [[ ! -e "$home_path" && ! -L "$home_path" ]]; then
    echo "error: $home_path does not exist" >&2
    exit 1
  fi

  if [[ -L "$home_path" ]]; then
    target="$(readlink "$home_path")"
    if [[ "$target" == "$DOTFILES_DIR"/* ]]; then
      echo "already linked: $home_path -> $target"
      exit 0
    fi
  fi

  repo_name="$(basename "$home_path")"
  target="$DOTFILES_DIR/$repo_name"

  if [[ -e "$target" || -L "$target" ]]; then
    echo "warning: $target already exists"
    if ! ask_overwrite "$target"; then
      exit 1
    fi
    rm -rf "$target"
  fi

  echo "moving $home_path -> $target"
  mv "$home_path" "$target"
  ensure_parent "$home_path"
  ln -s "$target" "$home_path"
  echo "link $home_path -> $target"

  list_dest="$(home_form "$home_path")"
  if [[ -f "$LIST_FILE" ]] && grep -Fxq "link $repo_name $list_dest" "$LIST_FILE"; then
    :
  else
    printf 'link %s %s\n' "$repo_name" "$list_dest" >> "$LIST_FILE"
    echo "appended to symlinks.txt"
  fi
}

main() {
  local cmd="${1:-}"
  shift || true
  case "$cmd" in
    link) cmd_link "$@" ;;
    sync) cmd_sync "$@" ;;
    *) usage ;;
  esac
}

main "$@"
