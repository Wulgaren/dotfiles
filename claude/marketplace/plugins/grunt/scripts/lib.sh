#!/usr/bin/env bash
# Shared worker plumbing for the grunt plugin.
#
# grunt_worker <backend> <model> <read|edit> "<prompt>" [session]
# runs one worker CLI in the current directory. Sets WORKER_TEXT,
# WORKER_SESSION ("backend:id"), WORKER_BACKEND and token counts, and exits
# non-zero with a readable reason when the run fails. A "backend:id" session
# resumes that worker instead of starting one.
#
# Backends: commandcode (workers, through the command-code CLI) and codex (the
# whole-task review). Config vars and defaults are documented in the plugin
# README.

GRUNT_MODEL="${GRUNT_MODEL:-}"
GRUNT_CODER_MODEL="${GRUNT_CODER_MODEL:-deepseek/deepseek-v4.1-flash-fast}"
GRUNT_REVIEW_MODEL="${GRUNT_REVIEW_MODEL:-gpt-6.2-sol}"
GRUNT_FALLBACK_MODEL="${GRUNT_FALLBACK_MODEL:-deepseek/deepseek-v4.1-flash}"
GRUNT_LOG="${GRUNT_LOG:-$HOME/.claude/grunt.log}"

# The editing worker's OS sandbox. On macOS, sandbox-exec fences every write to
# the worktree and the paths below, so a worker that ignores its spec still
# cannot reach the user's files. A Command Code deny rule cannot do this: it
# sees tools and commands, not shell redirects, and `echo x > ~/file` is
# neither. Set GRUNT_SANDBOX=0 to switch it off. Other platforms run unfenced.
GRUNT_SANDBOX="${GRUNT_SANDBOX:-1}"

# Commands an editing worker may not run. The worker runs under --yolo, which
# approves every command without a prompt, so this list is what stands between
# a worker and the user's data.
#
# A Command Code deny rule wins over --yolo and the allow list, and it matches
# each subcommand of a chain, so `cd x && rm y` is still refused. A wrapper
# such as `bash -c 'rm y'` or a full path is outside what the rule can see.
GRUNT_DENY=(
  'Shell(rm)' 'Shell(rmdir)' 'Shell(mv)' 'Shell(dd)' 'Shell(truncate)'
  'Shell(shred)' 'Shell(sudo)' 'Shell(git push)' 'Shell(git reset)'
  'Shell(git clean)' 'Shell(git restore)' 'Shell(git checkout)'
  'Shell(find)' 'Shell(npm install -g)'
)

# Paths the worker may write outside its worktree. The session temp dir is where
# a test runner and sandbox-exec itself need scratch space; the user's Command
# Code state is session bookkeeping, not project data.
GRUNT_SANDBOX_RW=(
  "$HOME/.commandcode"
  "${TMPDIR:-/tmp}"
  /private/tmp
  /private/var/folders
)

# sandbox_profile <worktree>
# Prints a macOS seatbelt profile that denies every write except the worktree
# and GRUNT_SANDBOX_RW. Reads stay open, which is what the worker needs.
sandbox_profile() {
  local worktree="$1" path
  printf '(version 1)\n(allow default)\n(deny file-write*)\n(allow file-write*\n'
  printf '  (subpath "%s")\n' "$worktree"
  for path in "${GRUNT_SANDBOX_RW[@]}"; do
    printf '  (subpath "%s")\n' "$path"
  done
  printf '  (subpath "/dev")\n)\n'
}

# The permission config handed to command-code, written into the worker's own
# .commandcode/settings.local.json so the deny list travels with the worker.
#
# commandcode_deny_json
commandcode_deny_json() {
  printf '%s\n' "${GRUNT_DENY[@]}" | jq -R . | jq -sc '{permissions: {deny: .}}'
}

WORKER_TEXT=""
WORKER_ERROR=""
WORKER_SESSION=""
WORKER_BACKEND=""
WORKER_IN=0
WORKER_OUT=0
WORKER_SECONDS=0

grunt_fail() {
  printf 'worker failed: %s\n' "$1" >&2
  printf 'Split the request into smaller calls, or do the work yourself.\n' >&2
  exit 1
}

# run_backend <commandcode|codex> <model> <access> <session> <prompt>
# Writes the CLI's output to $raw and stderr to $err (both owned by grunt_try),
# then parses it into WORKER_*. Returns 1 with RUN_ERROR set on any failure.
# GRUNT_EFFORT, when set, picks the commandcode reasoning effort.
run_backend() {
  local backend="$1" model="$2" access="$3" session="$4" input="$5" status=0
  local cmd=() prompt_arg="$input" binary="" profile=""
  case "$backend" in
    commandcode)
      # -p makes one headless run and streams NDJSON; its final `result` line
      # carries the answer. The prompt arrives on stdin.
      #
      # --trust answers the project-trust prompt and --skip-onboarding keeps a
      # first run from waiting on interactive setup.
      binary=command-code
      cmd=(command-code -p --output-format json --trust --skip-onboarding --no-skills)
      [[ -n "$model" ]] && cmd+=(--model "$model")
      [[ -n "${GRUNT_EFFORT:-}" ]] && cmd+=(--effort "$GRUNT_EFFORT")
      if [[ "$access" == edit ]]; then
        # --yolo answers every prompt. The deny list below wins over it and
        # over any allow rule, and the worker's own settings file keeps the
        # rest of the tree untouched.
        cmd+=(--yolo)
        mkdir -p "$PWD/.commandcode"
        commandcode_deny_json >"$PWD/.commandcode/settings.local.json"
        # A deny rule sees commands and tools, not shell redirects, so the OS
        # sandbox is what actually keeps writes inside the worktree.
        if [[ "$GRUNT_SANDBOX" == 1 ]] && command -v sandbox-exec >/dev/null; then
          profile="$(mktemp)"
          sandbox_profile "$PWD" > "$profile"
          cmd=(sandbox-exec -f "$profile" "${cmd[@]}")
        fi
      else
        # A reading worker gets read-only tools; anything that would need
        # approval is denied instead of asked.
        cmd+=(--permission-mode dont-ask)
      fi
      [[ -n "$session" ]] && cmd+=(--resume "$session")
      ;;
    codex)
      # codex exec reads the prompt from stdin, and -o keeps the final message
      # alone instead of mixing it with progress lines. --json carries the
      # per-turn token counts that -o drops, so the review is priced like a
      # worker instead of logging zero.
      binary=codex
      cmd=(codex exec -m "$model" -s read-only -C "$PWD" --json
        -c model_reasoning_effort=medium
        --output-last-message "$raw.msg")
      prompt_arg=""
      ;;
  esac

  if ! command -v "$binary" >/dev/null; then
    RUN_ERROR="$binary not on PATH"
    return 1
  fi

  [[ -n "$prompt_arg" ]] && cmd+=("$prompt_arg")

  # The workers load the project's own instruction files, so the guard stays off
  # for them: GRUNT_OFF=1 lets a worker read whole files.
  GRUNT_OFF=1 "${cmd[@]}" <<<"$input" >"$raw" 2>"$err" || status=$?
  [[ -n "$profile" ]] && rm -f "$profile"

  if (( status != 0 )); then
    RUN_ERROR="exit $status. $(tail -3 "$err" | tr '\n' ' ')"
    return 1
  fi
  if [[ "$backend" != codex ]] && ! jq -e . >/dev/null 2>&1 <"$raw"; then
    RUN_ERROR="no JSON. $(tail -3 "$err" | tr '\n' ' ')"
    return 1
  fi

  local id
  case "$backend" in
    commandcode)
      # The stream ends with one {"type":"result",...} line; everything above
      # it is progress.
      local result
      result="$(jq -sc 'map(select(.type == "result")) | last // empty' "$raw")"
      if [[ -z "$result" ]]; then
        RUN_ERROR="no result line. $(tail -3 "$err" | tr '\n' ' ')"
        return 1
      fi
      if [[ "$(jq -r '.subtype // "success"' <<<"$result")" != success ]]; then
        RUN_ERROR="$(jq -r '.finalText // .error // "run failed"' <<<"$result")"
        return 1
      fi
      WORKER_TEXT="$(jq -r '.finalText' <<<"$result")"
      id="$(jq -r '.sessionId // empty' <<<"$result")"
      WORKER_IN="$(jq -r '.usage.inputTokens // 0' <<<"$result")"
      WORKER_OUT="$(jq -r '.usage.outputTokens // 0' <<<"$result")"
      ;;
    codex)
      if [[ ! -s "$raw.msg" ]]; then
        RUN_ERROR="codex wrote no last message"
        return 1
      fi
      WORKER_TEXT="$(cat "$raw.msg" 2>/dev/null || true)"
      id=""
      # The last turn.completed carries the run's totals. Without them the
      # review logs zero and every savings figure reads high.
      local usage
      usage="$(jq -sc 'map(select(.type == "turn.completed")) | last // empty' "$raw" 2>/dev/null)"
      if [[ -n "$usage" ]]; then
        WORKER_IN="$(jq -r '.usage.input_tokens // 0' <<<"$usage")"
        WORKER_OUT="$(jq -r '.usage.output_tokens // 0' <<<"$usage")"
      else
        WORKER_IN=0
        WORKER_OUT=0
      fi
      ;;
  esac

  if [[ -z "${WORKER_TEXT//[[:space:]]/}" ]]; then
    RUN_ERROR="empty response"
    return 1
  fi
  WORKER_BACKEND="$backend"
  WORKER_SESSION="$backend:$id"
}

# Like grunt_worker, but returns 1 with WORKER_ERROR set instead of exiting, so
# a caller can fall back to another reviewer.
grunt_try() {
  local backend="$1" model="$2" access="$3" prompt="$4" session="${5:-}"
  local raw err started id="" resumed=""
  # A caller that must clean up after a killed worker gives grunt_try a
  # directory of its own, since its own rm never runs then.
  if [[ -n "${GRUNT_WORKER_TMP:-}" ]]; then
    raw="$GRUNT_WORKER_TMP/raw"
    err="$GRUNT_WORKER_TMP/err"
  else
    raw="$(mktemp)"
    err="$(mktemp)"
  fi
  started="$(date +%s)"

  # Resume only a session this backend can open. A session saved by a backend
  # or model the caller no longer uses is dropped, and the caller resends the
  # spec: code-write keeps the original under its review notes.
  if [[ -n "$session" ]]; then
    resumed="${session%%:*}"
    id="${session#*:}"
    if [[ "$resumed" != "$backend" || -z "$id" ]]; then
      printf 'grunt: ignoring %s session, it is not a %s session\n' "$resumed" "$backend" >&2
      id=""
    fi
  fi

  if ! run_backend "$backend" "$model" "$access" "$id" "$prompt"; then
    WORKER_ERROR="$RUN_ERROR"
    rm -f "$raw" "$raw.msg" "$err"
    return 1
  fi

  WORKER_SECONDS=$(($(date +%s) - started))
  rm -f "$raw" "$raw.msg" "$err"
}

# grunt_worker keeps the exit-on-failure contract bulk-read and step rely on.
grunt_worker() {
  grunt_try "$@" || grunt_fail "$WORKER_ERROR"
}

# grunt_log <mode> <detail> <lines> <bytes>
# Appends one TSV row; bytes estimate the main-context tokens avoided (bytes/4).
grunt_log() {
  local mode="$1" detail="$2" lines="$3" bytes="$4" avoided
  avoided="$(awk -v b="$bytes" 'BEGIN { printf "%d", b / 4 }')"
  {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(date '+%Y-%m-%dT%H:%M:%S')" "$mode" "$detail" \
      "${lines:--}" "${bytes:--}" "$avoided" \
      "$WORKER_SECONDS" "$WORKER_IN" "$WORKER_OUT" "${WORKER_BACKEND:--}"
  } >> "$GRUNT_LOG" 2>/dev/null || true
}
