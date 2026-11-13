#!/usr/bin/env bash
# Shared worker plumbing for the grunt plugin.
#
# grunt_worker "<prompt>" runs the cheap model, sets WORKER_TEXT plus token
# counts, and exits non-zero with a readable reason on failure.
#
# Config (env):
#   GRUNT_MODEL     worker model, default opencode-go/deepseek-v4.1-flash#low
#   GRUNT_TIMEOUT   seconds per call, default 120
#   GRUNT_LOG       usage log, default ~/.claude/grunt.log

GRUNT_MODEL="${GRUNT_MODEL:-opencode-go/deepseek-v4.1-flash#low}"
GRUNT_TIMEOUT="${GRUNT_TIMEOUT:-120}"
GRUNT_LOG="${GRUNT_LOG:-$HOME/.claude/grunt.log}"

WORKER_TEXT=""
WORKER_IN=0
WORKER_OUT=0
WORKER_SECONDS=0

grunt_fail() {
  printf 'worker failed: %s\n' "$1" >&2
  printf 'Retry with a smaller request, or read the file directly with offset/limit.\n' >&2
  exit 1
}

grunt_worker() {
  local prompt="$1" raw err status started ended

  command -v opencode >/dev/null || grunt_fail "opencode not on PATH"

  raw="$(mktemp)"
  err="$(mktemp)"

  started="$(date +%s)"
  timeout "$GRUNT_TIMEOUT" \
    opencode run --archived --format json -m "$GRUNT_MODEL" "$prompt" >"$raw" 2>"$err"
  status=$?
  ended="$(date +%s)"
  WORKER_SECONDS=$((ended - started))

  if (( status == 124 )); then
    rm -f "$raw" "$err"
    grunt_fail "timed out after ${GRUNT_TIMEOUT}s. Split the request into smaller calls."
  fi
  if (( status != 0 )); then
    local detail
    detail="$(tail -3 "$err" | tr '\n' ' ')"
    rm -f "$raw" "$err"
    grunt_fail "exit $status. ${detail:-no output}"
  fi
  if ! jq -e . >/dev/null 2>&1 <"$raw"; then
    rm -f "$raw" "$err"
    grunt_fail "worker returned no JSON. $(tail -3 "$err" | tr '\n' ' ')"
  fi

  WORKER_TEXT="$(jq -r 'select(.type == "text") | .part.text' "$raw")"
  WORKER_IN="$(jq -s '[.[] | select(.type == "step_finish") | .part.tokens.input // 0] | add // 0' "$raw")"
  WORKER_OUT="$(jq -s '[.[] | select(.type == "step_finish") | .part.tokens.output // 0] | add // 0' "$raw")"

  rm -f "$raw" "$err"

  if [[ -z "${WORKER_TEXT//[[:space:]]/}" ]]; then
    grunt_fail "empty response"
  fi
}

# grunt_log <mode> <detail> <lines> <bytes>
# Appends one TSV row; bytes estimate the main-context tokens avoided (bytes/4).
grunt_log() {
  local mode="$1" detail="$2" lines="$3" bytes="$4" avoided
  avoided="$(awk -v b="$bytes" 'BEGIN { printf "%d", b / 4 }')"
  {
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$(date '+%Y-%m-%dT%H:%M:%S')" "$mode" "$detail" \
      "${lines:--}" "${bytes:--}" "$avoided" \
      "$WORKER_SECONDS" "$WORKER_IN" "$WORKER_OUT"
  } >> "$GRUNT_LOG" 2>/dev/null || true
}
