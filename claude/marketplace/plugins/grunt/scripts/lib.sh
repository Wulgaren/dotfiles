#!/usr/bin/env bash
# Shared worker plumbing for the grunt plugin.
#
# grunt_worker <model> <switch_after> <limit> <read|edit> "<prompt>" [session]
# runs DeepSeek through opencode in the current directory for up to
# <switch_after> seconds. If it times out or fails, Cursor Auto takes over with
# the rest of <limit>. Sets WORKER_TEXT, WORKER_SESSION ("backend:id"),
# WORKER_BACKEND, WORKER_NOTE and token counts, and exits non-zero with a
# readable reason when both fail. A "cursor:" session skips DeepSeek.
# Config vars and defaults are documented in the plugin README.

GRUNT_MODEL="${GRUNT_MODEL:-opencode-go/deepseek-v4.1-flash#low}"
GRUNT_SWITCH_AFTER="${GRUNT_SWITCH_AFTER:-60}"
GRUNT_TIMEOUT="${GRUNT_TIMEOUT:-120}"
GRUNT_CODER_MODEL="${GRUNT_CODER_MODEL:-opencode-go/deepseek-v4.1-flash#high}"
GRUNT_CODER_SWITCH_AFTER="${GRUNT_CODER_SWITCH_AFTER:-220}"
GRUNT_CODER_TIMEOUT="${GRUNT_CODER_TIMEOUT:-540}"
GRUNT_REVIEW_MODEL="${GRUNT_REVIEW_MODEL:-openai/gpt-6.1-sol#medium}"
GRUNT_REVIEW_SWITCH_AFTER="${GRUNT_REVIEW_SWITCH_AFTER:-240}"
GRUNT_REVIEW_TIMEOUT="${GRUNT_REVIEW_TIMEOUT:-540}"
GRUNT_FALLBACK_MODEL="${GRUNT_FALLBACK_MODEL:-auto}"
GRUNT_LOG="${GRUNT_LOG:-$HOME/.claude/grunt.log}"

WORKER_TEXT=""
WORKER_SESSION=""
WORKER_BACKEND=""
WORKER_NOTE=""
WORKER_IN=0
WORKER_OUT=0
WORKER_SECONDS=0

grunt_fail() {
  printf 'worker failed: %s\n' "$1" >&2
  printf 'Split the request into smaller calls, or do the work yourself.\n' >&2
  exit 1
}

# run_backend <opencode|cursor> <model> <limit> <access> <session> <prompt>
# Writes the CLI's JSON to $raw and stderr to $err (both owned by grunt_worker),
# then parses it into WORKER_*. Returns 1 with RUN_ERROR set on any failure.
run_backend() {
  local backend="$1" model="$2" limit="$3" access="$4" session="$5" prompt="$6" status=0
  local cmd
  case "$backend" in
    opencode)
      cmd=(opencode run --archived --format json -m "$model")
      [[ "$access" == edit ]] && cmd+=(--auto)
      [[ -n "$session" ]] && cmd+=(--session "$session")
      ;;
    cursor)
      cmd=(agent -p --output-format json --trust --model "$model")
      if [[ "$access" == edit ]]; then cmd+=(--force); else cmd+=(--mode ask); fi
      [[ -n "$session" ]] && cmd+=(--resume "$session")
      ;;
  esac

  if ! command -v "${cmd[0]}" >/dev/null; then
    RUN_ERROR="${cmd[0]} not on PATH"
    return 1
  fi

  # The workers load Claude Code hooks too. GRUNT_OFF=1 lets them read whole files.
  GRUNT_OFF=1 timeout "$limit" "${cmd[@]}" "$prompt" >"$raw" 2>"$err" || status=$?

  if (( status == 124 )); then
    RUN_ERROR="timed out after ${limit}s"
    return 1
  fi
  if (( status != 0 )); then
    RUN_ERROR="exit $status. $(tail -3 "$err" | tr '\n' ' ')"
    return 1
  fi
  if ! jq -e . >/dev/null 2>&1 <"$raw"; then
    RUN_ERROR="no JSON. $(tail -3 "$err" | tr '\n' ' ')"
    return 1
  fi

  local id
  case "$backend" in
    opencode)
      WORKER_TEXT="$(jq -r 'select(.type == "text") | .part.text' "$raw")"
      id="$(jq -r '.sessionID // empty' "$raw" | head -1)"
      WORKER_IN="$(jq -s '[.[] | select(.type == "step_finish") | .part.tokens.input // 0] | add // 0' "$raw")"
      WORKER_OUT="$(jq -s '[.[] | select(.type == "step_finish") | .part.tokens.output // 0] | add // 0' "$raw")"
      ;;
    cursor)
      if jq -e 'select(.type == "result") | .is_error' >/dev/null "$raw"; then
        RUN_ERROR="$(jq -r 'select(.type == "result") | .result' "$raw")"
        return 1
      fi
      WORKER_TEXT="$(jq -r 'select(.type == "result") | .result' "$raw")"
      id="$(jq -r 'select(.type == "result") | .session_id' "$raw")"
      WORKER_IN="$(jq -r 'select(.type == "result") | .usage.inputTokens' "$raw")"
      WORKER_OUT="$(jq -r 'select(.type == "result") | .usage.outputTokens' "$raw")"
      ;;
  esac

  if [[ -z "${WORKER_TEXT//[[:space:]]/}" ]]; then
    RUN_ERROR="empty response"
    return 1
  fi
  WORKER_BACKEND="$backend"
  WORKER_SESSION="$backend:$id"
}

grunt_worker() {
  local model="$1" switch_after="$2" limit="$3" access="$4" prompt="$5" session="${6:-}"
  local raw err started first_error="" remaining ok=0
  raw="$(mktemp)"
  err="$(mktemp)"
  started="$(date +%s)"

  if [[ "$session" == cursor:* ]]; then
    run_backend cursor "$GRUNT_FALLBACK_MODEL" "$limit" "$access" "${session#cursor:}" "$prompt" && ok=1
  else
    if run_backend opencode "$model" "$switch_after" "$access" "${session#opencode:}" "$prompt"; then
      ok=1
    else
      first_error="$RUN_ERROR"
      remaining=$((limit - ($(date +%s) - started)))
      if [[ "$access" == edit ]]; then
        prompt="An earlier worker stopped before finishing this task. Its partial edits may still be in the tree. Run git status and git diff to see them, then finish the task.

$prompt"
      fi
      run_backend cursor "$GRUNT_FALLBACK_MODEL" "$remaining" "$access" "" "$prompt" && ok=1
      WORKER_NOTE="DeepSeek: $first_error. Switched to Cursor $GRUNT_FALLBACK_MODEL."
    fi
  fi

  WORKER_SECONDS=$(($(date +%s) - started))
  rm -f "$raw" "$err"

  if (( ! ok )); then
    grunt_fail "${first_error:+DeepSeek: $first_error. }Cursor: $RUN_ERROR"
  fi
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
