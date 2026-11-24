#!/bin/sh
# Claude Code statusline.
#
# Prints: rate limits | model | path (branch)
#
# Reads the status JSON that Claude Code sends on stdin. The git branch is not
# part of that JSON, so it is looked up with git in the current directory.

input=$(cat)

raw=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(printf '%s' "$input" | jq -r '.model.display_name // .model.id // empty')

dir="$raw"
case "$dir" in
  "$HOME"*) dir="~${dir#"$HOME"}" ;;
esac

branch=''
[ -n "$raw" ] && branch=$(git -C "$raw" branch --show-current 2>/dev/null)

right="$dir"
[ -n "$branch" ] && right="$right ($branch)"

# Local time from an epoch, on either BSD (macOS) or GNU (Linux) date.
fmt_time() {
  date -r "$1" "$2" 2>/dev/null || date -d "@$1" "$2" 2>/dev/null
}

f=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
fr=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
w=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
wr=$(printf '%s' "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

limits=''
[ -n "$f" ] && limits="5h $(printf '%.0f' "$f")%"
[ -n "$f" ] && [ -n "$fr" ] && limits="$limits (resets $(fmt_time "$fr" +%H:%M))"

if [ -n "$w" ]; then
  s="7d $(printf '%.0f' "$w")%"
  [ -n "$wr" ] && s="$s (resets $(fmt_time "$wr" '+%a %H:%M'))"
  limits="${limits:+$limits | }$s"
fi

line="$limits"
[ -n "$model" ] && line="${line:+$line | }$model"
[ -n "$right" ] && line="${line:+$line | }$right"

printf '%s\n' "$line"
