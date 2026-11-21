#!/usr/bin/env bash
# Shared worker plumbing for the grunt plugin.
#
# grunt_worker <backend> <model> <limit> <read|edit> "<prompt>" [session]
# runs one worker CLI in the current directory for up to <limit> seconds. Sets
# WORKER_TEXT, WORKER_SESSION ("backend:id"), WORKER_BACKEND and token counts,
# and exits non-zero with a readable reason when the run fails. A
# "backend:id" session resumes that worker instead of starting one.
#
# Backends: claude (workers, launched through the ocgo script) and codex (the
# whole-task review). Config vars and defaults are documented in the plugin
# README.

GRUNT_MODEL="${GRUNT_MODEL:-deepseek-v4.1-flash}"
GRUNT_TIMEOUT="${GRUNT_TIMEOUT:-120}"
GRUNT_EFFORT="${GRUNT_EFFORT:-low}"
GRUNT_CODER_MODEL="${GRUNT_CODER_MODEL:-deepseek-v4.1-flash}"
GRUNT_CODER_TIMEOUT="${GRUNT_CODER_TIMEOUT:-540}"
GRUNT_REVIEW_MODEL="${GRUNT_REVIEW_MODEL:-gpt-6.1-sol}"
GRUNT_REVIEW_TIMEOUT="${GRUNT_REVIEW_TIMEOUT:-540}"
GRUNT_LOG="${GRUNT_LOG:-$HOME/.claude/grunt.log}"

# Commands an editing worker may not run, mirroring the ask rules in
# opencode.json. acceptEdits approves every other Bash call without a prompt,
# so this list and the sandbox below are what stand between a worker and the
# user's data.
GRUNT_DENY=(
  'Bash(rm:*)' 'Bash(rmdir:*)' 'Bash(mv:*)' 'Bash(dd:*)' 'Bash(truncate:*)'
  'Bash(shred:*)' 'Bash(find * -delete*)' 'Bash(git clean:*)' 'Bash(git reset:*)'
  'Bash(git checkout --:*)' 'Bash(git checkout .)' 'Bash(git restore:*)'
  'Bash(git push:*)' 'Bash(sudo:*)' 'Bash(npm install -g*)'
)

# Claude Code's OS sandbox, which fences shell writes to the task's worktree.
# The deny list above cannot do this: a worker reaches any path with a shell
# redirect, and acceptEdits approves it. Set GRUNT_SANDBOX=0 to switch it off.
GRUNT_SANDBOX="${GRUNT_SANDBOX:-1}"

# The main repository an editing worker must not write to. code-write sets it
# to the tree the task will be applied to; empty for every other caller.
GRUNT_MAIN_ROOT="${GRUNT_MAIN_ROOT:-}"

# Paths a sandboxed worker may never write, whatever a settings file grants.
# allowWrite merges grants from user and project settings and from Edit allow
# rules, so a grant inherited from any of those reopens a path. denyWrite
# outranks every grant, which is what holds the fence.
#
# The main repository is on this list because it is the boundary that matters:
# the worker builds in a worktree and `finish` applies its work. A worker that
# writes to the main tree skips review entirely.
GRUNT_DENY_WRITE=(
  "$HOME/.ssh" "$HOME/.aws" "$HOME/.gnupg" "$HOME/.config/gh"
  "$HOME/.claude" "$HOME/Library" "$HOME/Documents" "$HOME/Desktop"
  /etc /usr /bin /sbin /opt /var /private/etc
)

# Settings JSON that confines the worker's shell writes to its working
# directory and refuses to run a command outside the sandbox. Claude Code maps
# a worker's own temp dir into that sandbox, so a test runner still has one.
#
# sandbox_settings <main-repo-root>
sandbox_settings() {
  local main="${1:-}"
  local deny
  deny="$(printf '%s\n' "${GRUNT_DENY_WRITE[@]}" $main | jq -R . | jq -sc .)"
  jq -nc --argjson deny "$deny" '{
    sandbox: {
      enabled: true,
      allowUnsandboxedCommands: false,
      filesystem: {denyWrite: $deny}
    }
  }'
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

# run_backend <claude|codex> <model> <limit> <access> <session> <prompt>
# Writes the CLI's output to $raw and stderr to $err (both owned by grunt_try),
# then parses it into WORKER_*. Returns 1 with RUN_ERROR set on any failure.
run_backend() {
  local backend="$1" model="$2" limit="$3" access="$4" session="$5" input="$6" status=0
  local cmd=() prompt_arg="$input"
  case "$backend" in
    claude)
      # ocgo execs claude with OpenCode Go's endpoint and key, so the worker is
      # independent of the provider running the main session.
      cmd=(ocgo -p --output-format json --model "$model" --effort "$GRUNT_EFFORT")
      # A worker must not reach for the grunt skills and start a worker of its
      # own, so its skills stay off. CLAUDE.md, hooks and plugins still load.
      cmd+=(--disable-slash-commands)
      if [[ "$access" == edit ]]; then
        cmd+=(--tools=Read,Grep,Glob,Edit,Write,Bash --allowedTools=Bash)
        cmd+=(--permission-mode acceptEdits --disallowedTools "${GRUNT_DENY[@]}")
        [[ "$GRUNT_SANDBOX" == 1 ]] && cmd+=(--settings "$(sandbox_settings "${GRUNT_MAIN_ROOT:-}")")
      else
        cmd+=(--tools=Read,Grep,Glob --permission-mode dontAsk)
      fi
      [[ -n "$session" ]] && cmd+=(--resume "$session")
      # --disallowedTools takes many values, so a trailing positional prompt
      # would be read as one of them. This prompt goes in on stdin instead.
      prompt_arg=""
      ;;
    codex)
      # codex exec reads the prompt from stdin, and -o keeps the final
      # message alone instead of mixing it with progress lines.
      cmd=(codex exec -m "$model" -s read-only -C "$PWD"
        -c model_reasoning_effort=medium
        --output-last-message "$raw.msg")
      prompt_arg=""
      ;;
  esac

  if ! command -v "${cmd[0]}" >/dev/null; then
    RUN_ERROR="${cmd[0]} not on PATH"
    return 1
  fi

  [[ -n "$prompt_arg" ]] && cmd+=("$prompt_arg")

  # The workers load Claude Code hooks too. GRUNT_OFF=1 lets them read whole files.
  GRUNT_OFF=1 timeout -k 10 "$limit" "${cmd[@]}" <<<"$input" >"$raw" 2>"$err" || status=$?

  if (( status == 124 )); then
    RUN_ERROR="timed out after ${limit}s"
    return 1
  fi
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
    claude)
      if [[ "$(jq -r '.is_error // false' "$raw")" == true ]]; then
        RUN_ERROR="$(jq -r '.result' "$raw")"
        return 1
      fi
      WORKER_TEXT="$(jq -r '.result' "$raw")"
      id="$(jq -r '.session_id' "$raw")"
      WORKER_IN="$(jq -r '.usage.input_tokens // 0' "$raw")"
      WORKER_OUT="$(jq -r '.usage.output_tokens // 0' "$raw")"
      ;;
    codex)
      if [[ ! -s "$raw.msg" ]]; then
        RUN_ERROR="codex wrote no last message"
        return 1
      fi
      WORKER_TEXT="$(cat "$raw.msg" 2>/dev/null || true)"
      id=""
      WORKER_IN=0
      WORKER_OUT=0
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
  local backend="$1" model="$2" limit="$3" access="$4" prompt="$5" session="${6:-}"
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

  if ! run_backend "$backend" "$model" "$limit" "$access" "$id" "$prompt"; then
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
