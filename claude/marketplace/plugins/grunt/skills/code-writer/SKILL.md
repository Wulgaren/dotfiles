---
name: code-writer
description: Hand a planned implementation step to the grunt worker, which edits files in a git worktree while you write the specs and gate the review when the task is done. Use for every step that writes new code, including the fix that ends a debugging session. Keep diagnosis, probes, and security, money and migration code for yourself; the fix goes to the worker, even when it is a few lines. Skip the review for presentation/CSS/copy/config when checks passed and you already read the full task diff.
---

# code-writer

You are the planner and reviewer. The worker writes the code. Each _step_ is a written _spec_ in, a committed diff out. Gate each step on its check. The review is gated (below), not automatic. The task lands in the user's working tree as uncommitted edits.

Script: `~/.claude/local-marketplace/plugins/grunt/scripts/code-write`. Run it from the main repository.

## Loop

1. **Plan.** Split the task into steps. Each step needs a spec the worker can follow alone and a check that proves it. Done when every step has a spec and a check command.

2. **Start.** `code-write start <task>` creates a worktree on branch `grunt/<task>` and prints its path. If the user's tree has uncommitted changes, the script stops. Ask the user whether the worker should build on those changes, then rerun with `--with-uncommitted` or `--from-head`. Done when the path is printed.

3. **Step.** `code-write step <task> --spec "<spec>" --check "<cmd>"`. The worker sees only the spec, so write it like a ticket for a capable stranger:
   - the files to change, and a neighbour file to mirror
   - the behaviour, with concrete inputs and outputs
   - the tests to write first when behaviour changes
   - what done looks like

   The check is the fastest command that proves the step, such as a focused test file or a typecheck. The worker loops on it, then the script runs it once more and prints the result, the worker's bullets, and the step diff.

   - Check passed: take the next step.
   - Check failed: `code-write step <task> --continue --spec "<notes>" --check "<cmd>"`, or fix it yourself with Edit on the worktree path. The next `step` or `finish` commits your fix. If the second try still fails, fix it yourself or `code-write abort <task>`.

   Done when every step's check has passed.

4. **Review.** When every step's check has passed, read the whole task diff against the plan and the repo's rules. Treat the worker's bullets as claims and the diff as truth.

   Each `step` already printed its own diff, so the task diff is usually complete in your context. Reopen a file in the worktree only when the diff leaves a question the diff cannot answer, and answer it in one call: `sed -n 'A,Bp'` over several ranges in a single Bash call costs one request, where one Read per file costs one each.

   **Run** `code-write review <task> --intent "<one sentence>"` (Sol on the full series, falling back to Command Code deepseek flash at high effort when Sol fails) only when any of these is true:
   - new or changed behaviour in logic, API, data, auth, money, or migrations
   - multi-file structural change (new module, shared helper, cross-layer wiring)
   - the check is weak relative to the risk (typecheck-only on a behaviour change, or no focused test where one belongs)
   - your own diff read finds a real risk and you want a second opinion

   **Skip** the review when all of these are true: checks passed; the diff is presentation, CSS, copy, config, or wiring (or a small self-fix after a prior pass); you personally read the full task diff and found nothing that needs another agent. Print `review: skipped (planner; <reason>)` and go to finish. `finish` does not require a prior `review: clean`.

   When you do run the review:
   - Findings are claims. Verify each against the code.
   - Small findings: fix them yourself in the worktree, re-read the delta, then **finish**. Do not re-run the review for planner self-fixes.
   - Larger findings: `code-write step <task> --continue --spec "<review notes>" --check "<cmd>"`, then review the series **once** more. Cap at one review round-trip per task unless a new high-severity risk appears after that continue.
   - The review runs on Sol and falls back to Command Code deepseek flash at high effort when Sol fails. A missing verdict is not clean; rerun the review once.

   On user stop or `code-write abort`, abort before starting another review. Abort kills an in-flight review for that task.

5. **Finish.** `code-write finish <task>` applies the whole task to the user's working tree, prints a diff stat, and deletes the worktree and branch. Continue the normal workflow (exercise the flow, build, cleanup) in the main tree. If the patch does not apply, the user's tree changed during the task. The worktree stays, so resolve it by hand.

## Limits

- Worktrees live under `~/.cache/grunt/<repo>-<task>` (`$XDG_CACHE_HOME` is honored), inside the home directory rather than the system temp dir, so container builds that mount `$HOME` can see them.
- The worktree holds tracked files, any carried edits, and links to a root-level `node_modules` or `.venv` (symlinks, or directory junctions on Windows). Other ignored files such as `.env` stay behind. When a check needs them, put the setup in the spec.
- The worker is a headless Command Code agent launched by `command-code` on `GRUNT_CODER_MODEL`, so it reads the project's CLAUDE.md and AGENTS.md but not your Claude Code hooks or plugins. `rm`, `del`, `git push`, `sudo` and the other commands in `GRUNT_DENY` come back to it as a refusal; it works around them and says so in its bullets. On macOS an OS sandbox fences its writes to the worktree, so a worker that ignores the spec cannot reach the user's files; `GRUNT_SANDBOX=0` turns that off. Windows has no OS fence, so the deny rules and your diff read are the boundary.
- `--continue` resumes the worker's session and resends the original spec under your notes, so a resumed worker sees the whole task. A session saved by a backend the plugin no longer uses is dropped with a note on stderr, and the step starts a fresh worker with that same resent spec.
