---
name: code-writer
description: Hand a planned implementation step to the grunt worker, which edits files in a git worktree while you write the spec and review the diff. Use for every step that writes new code, including the fix that ends a debugging session. Keep diagnosis, probes, and security, money and migration code for yourself; the fix goes to the worker, even when it is a few lines.
---

# code-writer

You are the planner and reviewer. The worker writes the code. Each _step_ is a written _spec_ in, a committed diff out. You review every diff before the next step, and the finished task lands in the user's working tree as uncommitted edits.

Script: `~/.claude/local-marketplace/plugins/grunt/scripts/code-write`. Run it from the main repository. Give every `step` call a Bash timeout of 600000.

## Loop

1. **Plan.** Split the task into steps, each one diff you can review in one pass. Done when every step has a spec and a check command.

2. **Start.** `code-write start <task>` creates a worktree on branch `grunt/<task>` and prints its path. If the user's tree has uncommitted changes, the script stops. Ask the user whether the worker should build on those changes, then rerun with `--with-uncommitted` or `--from-head`. Done when the path is printed.

3. **Step.** `code-write step <task> --spec "<spec>" --check "<cmd>"`. The worker sees only the spec, so write it like a ticket for a capable stranger:
   - the files to change, and a neighbour file to mirror
   - the behaviour, with concrete inputs and outputs
   - the tests to write first when behaviour changes
   - what done looks like

   The check is the fastest command that proves the step, such as a focused test file or a typecheck. The worker loops on it, then the script runs it once more and prints the result, the worker's bullets, and the step diff.

4. **Review.** Read every line of the diff against the spec and the repo's rules. Treat the worker's bullets as claims and the diff as truth.
   - Small problems: fix them yourself with Edit on the worktree path. The next `step` or `finish` commits your fix.
   - Big problems: `code-write step <task> --continue --spec "<review notes>" --check "<cmd>"`. This resumes the worker's session, so the notes only need to say what to change.
   - If the second try is still wrong, fix it yourself or `code-write abort <task>`.
   Done when the diff is one you would have written. Then take the next step.

5. **Review the series.** When every step is accepted, run `code-write review <task> --intent "<one sentence: what the user asked for>"`. GPT-6.1 Sol (through the `codex` CLI) and the `ocgo` worker read the commit list and the whole task diff at once and return findings. Sol is optional: a run that fails or times out is skipped, while a returned `changes-needed` verdict still fails the review. Per-step review misses what the steps add up to; this pass catches it before the code reaches the user's tree.

   - Findings are claims, like the worker's bullets. Verify each against the code.
   - Small findings: fix them yourself in the worktree.
   - Larger ones: send them back to the worker with `code-write step <task> --continue --spec "<review notes>" --check "<cmd>"`. The fix goes to the worker, never to the reviewer.

   Done when the review prints `review: clean`. An ocgo failure or a missing ocgo verdict is not clean, so rerun it.

6. **Finish.** `code-write finish <task>` applies the whole task to the user's working tree, prints a diff stat, and deletes the worktree and branch. Continue the normal workflow (exercise the flow, build, cleanup) in the main tree. If the patch does not apply, the user's tree changed during the task. The worktree stays, so resolve it by hand.

## Limits

- Worktrees live under `~/.cache/grunt/<repo>-<task>` (`$XDG_CACHE_HOME` is honored), inside the home directory rather than the system temp dir, so container builds that mount `$HOME` can see them.
- The worktree holds tracked files, any carried edits, and symlinks to a root-level `node_modules` or `.venv`. Other ignored files such as `.env` stay behind. When a check needs them, put the setup in the spec.
- The worker is a headless Claude session launched by `ocgo` on `GRUNT_CODER_MODEL` (OpenCode Go), so it sees your CLAUDE.md and hooks and has the same tools you do, minus skills. Its shell writes are fenced to the worktree, and `rm`, `git push`, `sudo` and the other commands in `GRUNT_DENY` come back to it as a refusal; it works around them and says so in its bullets.
- The worker gets the whole 540s step. A run that times out leaves its partial edits uncommitted in the worktree and exits non-zero with the reason. Inspect them with `git -C <worktree> diff`; the next `step` commits them along with any fixes of yours.
- `--continue` resumes the worker's session and resends the original spec under your notes, so a resumed worker sees the whole task. A session saved by a backend the plugin no longer uses is dropped with a note on stderr, and the step starts a fresh worker with that same resent spec.
