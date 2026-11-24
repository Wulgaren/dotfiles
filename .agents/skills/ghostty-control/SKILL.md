---
name: ghostty-control
description: Use when starting, typing into, or reading a Ghostty tab on the Mac: opening a tab on a command, sending text or keys, capturing the visible screen or scrollback.
---

# Controlling Ghostty on macOS

Ghostty 1.4+ ships an AppleScript dictionary (`/Applications/Ghostty.app/Contents/Resources/Ghostty.sdef`). Run these with `osascript` through the shell on the user's Mac. In a hosted agent (Cursor Cloud), pass that Mac's `machineId` from `ListMachines`. Auto-review may block AppleScript that types into a terminal; retry with the approval flag if the user asked for it.

## Objects

- `window` > `tab` > `terminal` (a surface). Useful properties: `id`, `name` (title), `working directory`, `pid` (foreground process), `tty`.
- Front tab's terminal: `focused terminal of selected tab of front window`.
- Commands: `new window`, `new tab`, `split`, `focus`, `select tab`, `close`, `close tab`, `close window`, `input text`, `send key`, `perform action`.

## Find the right terminal

```applescript
tell application "Ghostty"
  set out to {}
  repeat with w in windows
    repeat with t in tabs of w
      set s to focused terminal of t
      set end of out to {id of w, index of t, name of s, working directory of s, tty of s}
    end repeat
  end repeat
  return out
end tell
```

## Start something in a new tab

```applescript
tell application "Ghostty"
  activate
  set cfg to new surface configuration
  set initial working directory of cfg to "/Users/USER/Coding/PROJECT"
  set command of cfg to "opencode"
  set wait after command of cfg to true
  new tab in front window with configuration cfg
end tell
```

`wait after command` true keeps the tab open after the command exits. The configuration also takes `initial input`, `font size`, and `environment variables` (list of KEY=VALUE). Use `new window with configuration cfg` if no window exists.

## Type into a terminal

Use `input text "..." to <terminal>` and `send key` for Enter or other keys. Check the exact parameter syntax in the sdef (`grep -A6 'input text' Ghostty.sdef`) before first use.

## Read what a terminal shows

The dictionary has no text/contents property. Use the `write_screen_file` action (visible screen) or `write_scrollback_file` (full history) with `:copy`, which writes a temp file and puts its path on the clipboard. Save and restore the clipboard (text only) around it:

```bash
old=$(pbpaste)
osascript -e 'tell application "Ghostty" to perform action "write_screen_file:copy" on (focused terminal of selected tab of front window)'
sleep 1
p=$(pbpaste); printf '%s' "$old" | pbcopy
tail -n 40 "$p"
```

Target a specific terminal instead of the front one when several are open. Non-text clipboard contents (images) are lost by this.

## For opencode specifically

`opencode session list` and `opencode session export <id>` (run in the project directory) read sessions without touching the terminal at all; prefer them for status checks.
