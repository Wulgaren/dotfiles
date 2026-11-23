# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model: Cursor's `auto` mode, through the `cursor-agent` CLI. The worker is a separate headless Cursor agent, so it does not depend on whichever provider the main session runs on. It reads the project's `CLAUDE.md` and `AGENTS.md`, and picks up the project's `.cursor/hooks.json` when the working directory has one.

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** makes Claude the planner and reviewer. Claude writes a spec for each step. The worker runs as an agent in a git worktree, edits files, and loops on a check command. Each step is gated on its check. When the series is done, Claude reads the whole task diff. Dual-agent review (GPT-6.1 Sol through `codex`, plus `cursor-agent`) runs only when the skill says the task is review-worthy: behaviour/API/data risk, multi-file structure, weak checks, or a planner-requested second opinion. Presentation/CSS/copy/config that already passed its check skips Cursor+Sol after the planner's own diff read. Sol is optional on a run; a returned `changes-needed` still fails that review. Planner self-fixes then finish without a second dual review; a worker continue gets at most one more. `abort` kills an in-flight review. `finish` applies the task to the working tree as uncommitted edits.

The read guard works in Claude Code, Cursor, and OpenCode. `guard-read` owns the read rules; only the hook wiring differs.

| Agent | Skills | Guard |
|---|---|---|
| Claude Code | plugin `skills/` | plugin `hooks/hooks.json` |
| Cursor | `~/.cursor/skills` (dotfiles fan-out) | `.cursor/hooks/grunt-guard-read` via `preToolUse` |
| OpenCode | `~/.claude/skills` and `~/.agents/skills` | `opencode/plugins/grunt/index.ts` |

A `PreToolUse` hook routes reads two ways. Whole-file reads over `GRUNT_MIN_LINES` (default 1000) are blocked with a pointer to the skill, and generated files (lockfiles, minified assets, `node_modules`, `dist`) are blocked with a "use rg" message. Targeted reads (`offset`/`limit`) pass through.

Shell reads that the block rule cannot see, such as `sed -n 100,260p f` or `cat a; sed -n 1,140p b`, are capped at `GRUNT_MAX_BYTES` (default 6000). The hook rewrites the command so it still runs once, keeps the first 6000 bytes of stdout, and appends a marker with the full size plus the two ways to get the rest: an exact range or a bulk-read question. stderr and the exit code pass through unchanged. The rewrite returns `permissionDecision: allow`, so a capped command does not go through the permission prompt.

## Install

```
claude plugin marketplace add ~/.claude/local-marketplace
claude plugin install grunt@natios
```

The marketplace lives in this dotfiles repo under `claude/marketplace` and is linked to `~/.claude/local-marketplace`.

The worker needs the `cursor-agent` CLI on `PATH`, signed in with `cursor-agent login`. The Sol review needs the `codex` CLI on `PATH`, signed in to an account that can reach `GRUNT_REVIEW_MODEL`.

Cursor and OpenCode need no install step. The plugin skills are linked into `.cursor/skills`, `link.sh sync` fans them out to the agent config directories, and OpenCode discovers `opencode/plugins/grunt` from the linked config directory.

## Config

Set in `~/.claude/settings.json` under `env`:

| Var | Default | Meaning |
|---|---|---|
| `GRUNT_MIN_LINES` | `1000` | Block reads above this line count |
| `GRUNT_MAX_BYTES` | `6000` | Cap on shell read stdout; the command runs once and the cut is marked |
| `GRUNT_MODEL` | `auto` | bulk-read model |
| `GRUNT_CODER_MODEL` | `auto` | code-write model |
| `GRUNT_REVIEW_MODEL` | `gpt-6.1-sol` | Sol's codex model |
| `GRUNT_SANDBOX` | `1` | Fence an editing worker's writes |
| `GRUNT_OFF` | unset | `1` disables the read guard |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

`GRUNT_MODEL` and `GRUNT_CODER_MODEL` are `cursor-agent` model names; `cursor-agent models` lists them, and `auto` lets Cursor pick. `GRUNT_REVIEW_MODEL` is a codex CLI model name. The cursor reviewer runs on `GRUNT_CODER_MODEL`.

## The editing worker's reach

An editing worker runs with `--trust`, so a permission prompt never stops it, and it can run any shell command the deny list does not name. Two things fence that in.

- `--sandbox enabled` is the write fence. A worker that writes outside its working directory gets `operation not permitted`, and its retry with elevated permissions is refused. `code-write`'s worktree is therefore the only place an editing worker can write, and the main repository stays out of reach without naming any path. macOS `/tmp` is the exception: the sandbox treats it as scratch space.
- `GRUNT_DENY` in `lib.sh` lists the commands the worker may not run. The worker carries that list in its own `.cursor/cli.json`, so `code-write` needs no install in your tree. A denied call comes back to the worker as a refusal, not a prompt.

Cursor matches a deny entry as a command prefix and blocks it wherever the command appears, so the list does not have to spell out `cd x && rm y`, `bash -c 'rm y'` or `/bin/rm y`; a probe confirmed all three are refused.

A reading worker runs in `ask` mode, which offers it reading and analysis only. A bulk-read worker and the cursor reviewer therefore carry no deny list.

The write fence is not a read fence: a worker reads whatever you can read.


## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out  backend
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

Guard rows stop after `bytes`: `blocked-bulk` and `blocked-generated` from the whole-file rule, `capped-read` from the shell cap. For `capped-read`, `lines` and `bytes` are the estimate from the command, not the truncated output.

## Limits

Delegation covers understanding, not editing, debugging, or design decisions. Each skill lists when not to use it.
