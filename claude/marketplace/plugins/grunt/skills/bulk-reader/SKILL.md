---
name: bulk-reader
description: Read many large files and answer one question about them without loading the files into your context. Use when a read is blocked by the grunt hook, or when answering a question requires reading files over roughly 350 lines. Not for editing, debugging, or design decisions.
---

# bulk-reader

Sends files to a cheap worker model and returns a short bullet answer. The files never enter your context.

## When to use it

- A read was blocked as too large.
- A question spans several files and you need understanding, not exact lines.
- You are about to read a file mostly to find one thing in it.

## When not to use it

- You will edit the file. The worker's line numbers drift. Read the exact range with offset/limit.
- You are debugging a specific failure or making a design, security, or correctness call. Those need the real code.
- You need to grep. Use `rg` directly, it is cheaper than either option.

## Usage

```
${CLAUDE_PLUGIN_ROOT}/scripts/bulk-read --question "How does token refresh work?" --paths src/auth.ts src/client.ts
```

- One specific question per call. Vague questions produce vague bullets.
- Follow-up question on the same files: run it again with the new question. Re-sending is cheap.
- Works over any file type, up to about 400 KB total per call.
- Answers come back as bullets led by file name and line number. Treat them as a map, not as truth.

## Config

`GRUNT_MIN_LINES` (default 350) sets the size at which reads are blocked. `GRUNT_OFF=1` disables the guard. `GRUNT_MODEL` changes the worker. Set them in `~/.claude/settings.json` under `env`.
