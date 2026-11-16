---
name: handoff
description: Compact the current conversation into a project memory note so a fresh agent picks up where this one stopped. Use when the session is long, before compacting, or when the user asks for a handoff.
argument-hint: "What will the next session be used for?"
---

Write the state of the current conversation as a memory note, so a fresh agent continues the work without re-deriving it.

Save it to the project's memory directory: `~/.claude/projects/<the working directory with every / replaced by ->/memory/`. Create the directory if it is missing. Both agents read this directory at session start, OpenCode through the project's `instructions` glob, so the note arrives without being pasted.

Use the frontmatter the other notes there already use:

```
---
name: <slug>
description: "<one line: what this note holds>"
metadata:
  node_type: memory
  type: project
  modified: <ISO date>
---
```

Then add one line to `MEMORY.md` in the same directory: `- [<title>](<slug>.md) — <what it holds>`.

Cover what a fresh session cannot recover from the repo: the decision and why, the current state (branch, worktree, uncommitted files, what passes and what does not), and the open questions with the options for each. Include a "suggested skills" section naming which skills the next agent should call.

Update the note that already covers the subject. Every note is loaded at the start of every session, so keep the set small and each note current.

Reference artifacts by path or URL (specs, plans, ADRs, issues, commits, diffs) instead of copying them in.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the note accordingly.
