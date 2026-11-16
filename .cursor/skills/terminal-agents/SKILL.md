---
name: terminal-agents
description: >
  Use when reading, steering, or approving an AI coding agent (opencode, Claude
  Code, Cursor agent CLI) in a Ghostty tab on the Mac: answering the question it
  asked, approving or rejecting a plan or a permission prompt, switching its
  mode, sending a follow-up. Load before typing into any terminal.
---

# Driving AI coding agents in a terminal

This skill builds on `ghostty-control`, which covers finding Ghostty terminals, opening tabs, `input text`, `send key`, and reading the screen. Load it too. Run everything through the Shell tool against the user's Mac; in a hosted agent (Cursor Cloud) pass that Mac's `machineId` from `ListMachines`. Typing into a terminal can trip Auto-review. When the user asked for that exact action, retry it with the approval flag.

## Rules

- Only act in a session the user pointed you to, or one you clearly identified (title, cwd, tty). Never type into a tab you haven't identified.
- Read the screen before every keystroke and again after it. TUIs re-render, and a key sent to the wrong state can approve something.
- Never approve a permission, "always allow", "Run Everything", "Yes, and use auto mode", or bypass mode unless the user picked that exact option. Relay the options instead.
- Keep `~/.config/opencode/service.json` (the server password) unread; `opencode api` handles auth for you.

## 1. Pick a route (most reliable first)

| Agent | Best route | Live TUI sees it? |
|---|---|---|
| opencode | `opencode api <operationId>` against the background server (`opencode serve --service`) | **Yes** (verified). The TUI is a client of the same server, so API prompts, question answers and agent changes show up live. |
| Claude Code | Keystrokes into its Ghostty tab. Read state from `claude agents --json` and `~/.claude/sessions/<pid>.json`. | `claude -p --resume <id>` appends to the same transcript but the open TUI does **not** show it (verified). Use headless only for sessions with no TUI open, or add `--fork-session`. |
| Cursor agent | Keystrokes into its Ghostty tab | `cursor-agent -p --resume <chatId>` works and writes into the same chat, but the open TUI does **not** show it (verified). Same caveat as Claude. |

If there's no tmux on the Mac, `cursor-agent persist` and `claude --tmux` are unavailable.

## 2. Find the session and its terminal

List terminals with id, title, tty, and cwd:

```bash
osascript -e 'tell application "Ghostty"
set out to ""
repeat with w in windows
repeat with t in tabs of w
repeat with s in terminals of t
set out to out & (id of s) & " | " & (name of s) & " | " & (tty of s) & " | " & (working directory of s) & linefeed
end repeat
end repeat
end repeat
return out
end tell'
ps -axo pid,tty,comm | /usr/bin/grep -E 'claude|opencode|cursor-agent|agent$'   # plain `grep` may be aliased to rg in zsh
```

- **opencode**: the title is `OC | <session title>`. `opencode api session.list --param limit=10` returns `id`, `title`, `agent`, and `location.directory`. `opencode api session.active` lists the sessions that are running right now. Match on title plus directory.
- **Claude Code**: the title is `<spinner glyph> <session name or task>`. Match the terminal's `tty` to the `claude` pid in `ps`, then read `~/.claude/sessions/<pid>.json` for `sessionId`, `cwd`, `name`, `status`, and `waitingFor`. `claude agents --json` (no TTY needed) lists the same for every interactive and background session.
- **Cursor agent**: chats live in `~/.cursor/chats/<md5 of the real cwd>/<chatId>/` (`meta.json` and `store.db`). Hash the resolved path: `echo -n /private/tmp/x | md5`, since `/tmp` resolves to `/private/tmp`. Plans are saved to `~/.cursor/plans/*.plan.md`. Map the terminal by tty and cwd.

Always address a terminal by id, never with "front window". The user may switch tabs at any time.

## 3. Read the screen

The `ghostty-control` read recipe can fail silently: when it does, `pbpaste` returns the user's own clipboard. Use this guarded version instead, which restores the clipboard and prints the screen only if it got a real file path:

```bash
read_screen() { # $1 = terminal id, $2 = screen|scrollback
  local old p ok; old=$(pbpaste 2>/dev/null); printf '' | pbcopy
  ok=$(osascript -e "tell application \"Ghostty\" to perform action \"write_${2:-screen}_file:copy\" on (terminal id \"$1\")" 2>&1)
  for i in $(seq 1 30); do p=$(pbpaste); [ -n "$p" ] && break; sleep 0.1; done
  printf '%s' "$old" | pbcopy
  case "$p" in /*) [ -f "$p" ] && { sed -e 's/[[:space:]]*$//' "$p" | cat -s; return 0; };; esac
  echo "screen read failed ($ok)" >&2; return 1
}
read_screen <TERMINAL_ID> | tail -40
```

Only text clipboard contents are kept. An image on the clipboard is lost. The text has no colours, so opencode's highlighted row can't be seen. Claude Code (`❯`) and Cursor (`→` / `▶`) draw a visible cursor glyph.

## 4. Recognise the state (snippets verified live)

### opencode 2.3

- Question (question tool):

  ```
  ┃  Questions
  ┃  Which color do you like?
  ┃  1. Red
  ┃  2. Green
  ┃  4. Type your own answer
  ┃  ↑↓ select  enter submit  esc dismiss
  ```

  Through the API: `opencode api session.form.list --param sessionID=<ses>` returns `metadata.kind:"question"` and `fields[{key:"q0", options:[{value,label}], custom:true}]`.
- Idle: the footer shows `Build auto · <model>` (or `Plan …`) and `ctrl+p commands`. `session.active` doesn't list it.
- Permission: `opencode api session.permission.list --param sessionID=<ses>` (or `permission.request.list`) returns `action` and `resources`. TUI layout not verified.

### Claude Code 2.1

- Question (AskUserQuestion):

  ```
   ☐ Color
  Which color do you like?
  ❯ 1. Red
       Write "red" to colors.txt
    2. Green
    4. Type something.
    5. Chat about this
  Enter to select · ↑/↓ to navigate · Esc to cancel
  ```
- Plan approval (ExitPlanMode): `Ready to code?` … `Here is Claude's plan:` … `❯ 1. Yes, and use auto mode / 2. Yes, manually approve edits / 3. Tell Claude what to change` (with the hint `shift+tab to approve with this feedback`) … `ctrl+g to edit in Vim · ~/.claude/plans/<name>.md`. The full plan is in that file.
- Permission: `Bash command` … `Do you want to proceed?` `❯ 1. Yes / 2. Yes, and always allow … / 3. Yes, and switch to auto mode / 4. No` … `Esc to cancel · Tab to amend`.
- While waiting on any of these, `~/.claude/sessions/<pid>.json` has `"status":"waiting","waitingFor":"permission prompt"` (seen for plan approval). Otherwise the status is `busy` while working and `idle` or `shell` when not (other values unverified).
- Working: `✳ Wandering… (5s · ↓ 384 tokens)` and the footer `· esc to interrupt`.
- Idle: an empty `❯` prompt box, with the mode line underneath, e.g. `⏸ plan mode on (shift+tab to cycle)`.
- Trust dialog in a new folder: `Accessing workspace: … ❯ No, exit / Yes, I trust this folder`. **The default is "No, exit".**

### Cursor agent 2026.11

- Plan: a `Suggested Plan` box, then `Ready to build?` `→ 1. Yes, build locally (b)` and `2. No, propose changes (p or Esc)`. After `p`, the prompt reads `→ Describe how to revise the plan (Enter to submit, Esc to cancel)`.
- Permission: `Run this command?` `Not in allowlist: touch` `→ Run (once) (y)`, `Add Shell(touch) to allowlist? (tab)`, `Run Everything (shift+tab)`, `Skip & tell the agent what to do instead (esc or n)`.
- Questions: the CLI had **no** ask-question tool in testing. The model printed a numbered list as plain text, so answer it with a normal follow-up message.
- Idle: `→ Add a follow-up`. The mode line shows `Plan (shift+tab to cycle)`, `Ask …`, or `Debug …`. Agent mode has no label.
- Trust dialog: `▶ [a] Trust this workspace / [q] Quit`.

## 5. Key and API cheat sheet

Ghostty key names are camelCase: `enter`, `escape`, `tab`, `arrowUp`, `arrowDown`, `arrowLeft`, `arrowRight`, `backspace`, `space`, letters `a`–`z`, digits `digit1`–`digit9`. `"down"`, `"arrow_down"`, and `"3"` are rejected. Modifiers: `modifiers "shift"`, `"control"`, `"option"`, `"command"`.

```bash
key()  { osascript -e "tell application \"Ghostty\" to send key \"$2\" ${3:+modifiers \"$3\"} to terminal id \"$1\""; }
text() { osascript -e "tell application \"Ghostty\" to input text \"$2\" to terminal id \"$1\""; }  # pasted; escape quotes and backslashes
# send a message: text T "msg"; sleep 0.4; key T enter
```

`input text` pastes the text without submitting it, so send `enter` separately. For a newline inside a message, use `key T enter shift` (Claude and opencode).

### opencode (API, preferred)

Run `opencode api <operationId> --param k=v -d '<json>'` in any directory.

- Read: `session.list`, `session.active`, `session.get --param sessionID=…`, `session.message.list --param sessionID=… --param limit=20 --param order=desc`.
- Answer a question: `session.form.reply --param sessionID=… --param formID=frm_… -d '{"answer":{"q0":"Green"}}'`. Use an option's `value`, or any text when `custom:true`. Multiselect takes an array. Verified: the TUI updates and the agent continues.
- Permission: `session.permission.reply --param sessionID=… --param requestID=… -d '{"decision":"once"|"always"|"reject","message":"optional feedback"}'` (from the API schema, not run live).
- Send a message: `session.prompt --param sessionID=… -d '{"text":"…"}'`. Verified: it shows in the live TUI. The optional `"delivery":"steer"|"queue"` defaults to steer.
- Interrupt: `session.interrupt --param sessionID=…`. Wait until idle: `experimental.session.wait --param sessionID=…` (both from the schema).
- Global lists are scoped by directory, so pass the *resolved* path: `form.list --param 'location[directory]=/private/tmp/x'`. `/tmp/x` returned nothing. The per-session `session.form.list` avoids this.
- Plan mode is just the `plan` agent: edits are denied except plan files, and there's no approval dialog. To "approve", switch to `build` and send "implement the plan". `session.switchAgent -d '{"agent":"build"}'` changes the session's agent, but the open TUI keeps the agent shown in its own prompt box and uses it for the next message typed there. If the TUI might be used, switch with keys instead.
- Full endpoint list: `opencode api GET /openapi.json`. Avoid `config.get` and `credential.*`, which may expose secrets.

### opencode (TUI keys)

In a question, use `arrowDown`/`arrowUp` then `enter`. Starting from option 1, one `arrowDown` then `enter` picked option 2 (verified). For free text, move to "Type your own answer" (exact flow unverified). `escape` dismisses a question or interrupts work. `shift+tab` cycles agents Build⇄Plan (verified). `ctrl+p` opens commands.

### Claude Code (TUI keys)

- Questions and pickers: `digitN` picks and submits option N at once (verified). Arrows plus `enter` also work. For free text, pick the "Type something." row, then type and press `enter` (docs: double `escape` there cancels the question). Left/right switches question tabs when there are several (docs). Multi-select toggling is unverified.
- Plan: `digit1` approves with auto mode and `digit2` approves with manual edits. Avoid both unless the user chose them. To revise, press `digit3`: the cursor moves to the row and stays there, then type the feedback and press `enter`. Claude re-plans and asks again (verified). `escape` rejects the plan and stays in plan mode, idle (verified). The full plan text is in the `~/.claude/plans/<name>.md` file shown on screen.
- Permission: `digit1` allows once and `digit4` (or `escape`) says No, which shows `Interrupted · What should Claude do instead?` (verified). `digit2` writes a permanent allow rule, so use it only when asked.
- Modes: `shift+tab` cycles auto → manual → accept edits → plan → auto (verified). Check the mode line after each press. You can also start with `claude --permission-mode plan|acceptEdits|manual|auto`.
- Interrupt: `escape` while working (`ctrl+c` also interrupts, and a second press on an empty prompt exits). Typing plus `enter` while it works queues the message instead of interrupting (docs).

### Cursor agent (TUI keys)

- Plan: `b` builds and `p` or `escape` opens "propose changes". Type the revision and press `enter` (verified: it updated the plan file without building). `escape` in the revise box bounces back to the picker, so to leave you have to send a revision.
- Permission: `y` runs once and `n` or `escape` skips, which opens "Tell the agent what to do instead". Type a reason and press `enter`, or press `enter` on an empty box to skip (verified). **`shift+tab` here means "Run Everything", and `tab` adds to the allowlist.**
- Modes: `shift+tab` cycles Agent → Plan → Debug → Ask → Agent (verified). You can also start with `--plan` or `--mode ask`.
- Interrupt: `ctrl+c` (the footer shows `ctrl+c to stop` while waiting). `escape` behaviour while working is unverified.

## 6. Relay the choice to the user (widget pattern)

1. Read the state (opencode: `session.form.list` / `session.permission.list`; others: `read_screen`).
2. Pull out the question, every option label (plus description), and which ones are dangerous (always-allow, run-everything, auto mode).
3. Offer them as a widget with the labels word for word, plus an "other / type my own" choice when the agent allows free text. For plans, summarise the plan (read the plan file) and offer: Approve (name the exact mode), Revise (ask what to change), Reject.
4. Send the pick with the matching route above, then read again and confirm the agent moved on (question answered, `status` back to busy, or the plan box gone). Report back in one line.

## Pitfalls

- **Mode keys inside dialogs approve things.** With a permission or plan box open, `shift+tab` means "Run Everything" (Cursor) or "approve with feedback" (Claude). Cycle modes only when the agent is idle and the screen shows the empty prompt.
- Claude's digit keys submit immediately. A digit on a free-text row only moves the cursor.
- Trust dialogs differ: Claude defaults to "No, exit", while Cursor takes `a`.
- Headless `-p --resume` into a session that is open in a TUI splits the history the user sees. Prefer keys, or `--fork-session` for Claude.
- `pbpaste` can return the user's own clipboard if the screen action fails. Never print it. Use the guarded `read_screen`.
- Wide screens wrap long option text. Match options by number or prefix, not the full line.
- Free-text pastes: escape `"` and `\` for AppleScript. Claude Code may collapse big pastes into `[Pasted text #N]`, which is still sent.
- Closing a window you opened: `close window (first window whose id is "<id>")`. `close w` fails.
- opencode reports the real path (`/private/tmp/...`) in directories and titles.
