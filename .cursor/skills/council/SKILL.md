---
name: council
description: Trigger this if the user says 'council'.
---

# Council

Three delegates from three providers review the same checkout at once, and the
work repeats until all three approve. Run each command from the repo root so
every delegate sees the same files.

## Delegates

| Delegate | CLI | Model | Command |
| --- | --- | --- | --- |
| Cursor | `cursor-agent` | Grok 4.7 xhigh | `cursor-agent -p --mode ask --trust --model grok-4.7-xhigh "<prompt>"` |
| DeepSeek | `opencode` | `opencode-go/deepseek-v4.1-flash` | `opencode run --model opencode-go/deepseek-v4.1-flash --agent plan "<prompt>"` |
| OpenAI | `opencode` | `openai/gpt-6.1-sol` | `opencode run --model openai/gpt-6.1-sol --agent plan "<prompt>"` |

Both CLIs run read-only: `--mode ask` for Cursor, the `plan` agent for
OpenCode. If the user names council members, use those. If a delegate cannot
start, report which one and why, and keep the other two running.

## Steps

1. Get the work ready. Address outstanding PR comments, fix known issues, and
   run the relevant checks. Hand the delegates the updated implementation.
   When the user wants to replace the implementation, skip fixes to code being
   replaced. Done when known issues are fixed or deliberately out of scope.

2. Dispatch all three delegates in parallel, one command per row above. Each
   prompt names the request, points at the repo and the diff
   (`git diff <base>...HEAD`), and asks for findings plus a score out of 10.
   Done when all three jobs are running.

3. Chase the results as they land. Check each finding against the code and
   decide what to fix. Edit files only after every delegate has returned, so
   no delegate reviews a checkout that moves under it. Done when all three
   results are in and each finding is fixed or rejected with a reason.

4. Request a fresh review from all three after the fixes. One full pass of all
   three counts as a round. Repeat until every delegate is satisfied. Done
   when all three approve, or one stays unavailable and you have said so.

Keep the change from growing round over round. Fix what the delegates find,
and leave scope alone otherwise.

## Report

For a pull request, edit the description and add this section:

```markdown
## Council review

Rounds: 2

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Grok 4.7 | 7/10 | 9/10 |
| DeepSeek | 8/10 | 10/10 |
| GPT 6.1 Sol | 7/10 | 9/10 |
```

Write `no score` when a delegate gives none. Do not invent a score. Edit the
description instead of posting a comment. Without a PR, put the same table in
the final reply.
