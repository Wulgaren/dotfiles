# Ask a second model about a snippet, a file, or a question, without moving the
# main Claude Code session off its own model.
#
#   ask "why does this regex fail on trailing whitespace?"
#   cat parser.ts | ask "name the bug in this function"
#   ask -f src/parse.ts "find the off-by-one"
#   ask -m kimi-k3.1-pro -f db.ts "is this query safe in a transaction?"
#   git diff | ask --code "write the commit message"
#
# stdin is sent as context when it is not a terminal, so it composes with pipes.
# The answer goes to stdout, progress to stderr, so `ask ... > out.md` stays clean.

ASK_MODEL="opencode-go/deepseek-v4.1-flash"
ASK_TIMEOUT=180

ask_usage() {
  cat <<'EOF'
ask — send a snippet or question to a second model

Usage:
  ask [options] "question"
  cat file | ask [options] "question"

Options:
  -f, --file PATH     Attach a file as context (repeatable)
  -m, --model MODEL   Worker model (default: opencode-go/deepseek-v4.1-flash)
  -c, --code          Ask for code only, no prose
  -t, --timeout SECS  Give up after SECS (default: 180)
  -h, --help          Show this help

Models come from `opencode models`. The OpenCode Go plan covers
opencode-go/* (deepseek, kimi, glm, qwen, minimax), openai/*,
and claude-haiku-5-5.

Examples:
  ask "explain this stack trace: TypeError at parse.ts:42"
  cat main.rs | ask "what does the lifetime bound on line 12 mean?"
  ask -m kimi-k3.1-pro -f migrations/001.sql "will this lock the table?"
EOF
}

ask() {
  local model="$ASK_MODEL" timeout_secs="$ASK_TIMEOUT" code_only=false
  local -a files=()
  local question=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) ask_usage; return 0 ;;
      -f|--file) files+=("$2"); shift 2 ;;
      -m|--model) model="$2"; shift 2 ;;
      -t|--timeout) timeout_secs="$2"; shift 2 ;;
      -c|--code) code_only=true; shift ;;
      --) shift; question="$*"; break ;;
      -*) echo "ask: unknown option $1" >&2; ask_usage >&2; return 2 ;;
      *) question="$*"; break ;;
    esac
  done

  if [[ -z "$question" ]]; then
    echo "ask: no question given" >&2
    ask_usage >&2
    return 2
  fi

  if ! command -v opencode >/dev/null; then
    echo "ask: opencode is not on PATH" >&2
    return 1
  fi

  local prompt="" file
  for file in "${files[@]}"; do
    if [[ ! -f "$file" ]]; then
      echo "ask: no such file: $file" >&2
      return 1
    fi
    prompt+="File: ${file}"$'\n```\n'"$(cat "$file")"$'\n```\n\n'
  done

  if [[ ! -t 0 ]]; then
    local piped
    piped="$(cat)"
    [[ -n "${piped//[[:space:]]/}" ]] && prompt+="Input:"$'\n```\n'"${piped}"$'\n```\n\n'
  fi

  prompt+="$question"
  $code_only && prompt+=$'\n\nAnswer with code only. No explanation, no markdown fences.'

  echo "ask: ${model}" >&2

  local raw rc=0
  raw="$(mktemp)"
  # GRUNT_OFF stops the read guard from capping the worker's own file reads.
  GRUNT_OFF=1 timeout "$timeout_secs" opencode run --archived --format json \
    -m "$model" "$prompt" >"$raw" 2>/dev/null || rc=$?

  if (( rc != 0 )); then
    rm -f "$raw"
    if (( rc == 124 )); then
      echo "ask: timed out after ${timeout_secs}s" >&2
    else
      echo "ask: opencode failed (exit $rc)" >&2
    fi
    return 1
  fi

  local answer
  answer="$(jq -r 'select(.type == "text") | .part.text' "$raw" 2>/dev/null)"
  rm -f "$raw"

  if [[ -z "${answer//[[:space:]]/}" ]]; then
    echo "ask: empty response from ${model}" >&2
    return 1
  fi

  printf '%s\n' "$answer"
}
