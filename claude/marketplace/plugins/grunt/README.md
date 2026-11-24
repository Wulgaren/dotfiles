# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model through the `command-code` CLI. The worker is a separate headless Command Code agent, so it does not depend on whichever provider the main session runs on. It reads the project's `CLAUDE.md` and `AGENTS.md`, and picks up the project's `.commandcode` settings when the working directory has one.

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** makes Claude the planner and reviewer. Claude writes a spec for each step. The worker runs as an agent in a git worktree, edits files, and loops on a check command. Each step is gated on its check. When the series is done, Claude reads the whole task diff. One review pass (GPT-6.2 Sol through `codex`) runs only when the skill says the task is review-worthy: behaviour/API/data risk, multi-file structure, weak checks, or a planner-requested second opinion. When Sol is missing, signed out, or out of credits, the same review runs on Command Code's `deepseek/deepseek-v4.1-flash` at high effort. Presentation/CSS/copy/config that already passed its check skips the review after the planner's own diff read. Planner self-fixes then finish without a second review; a worker continue gets at most one more. `abort` kills an in-flight review. `finish` applies the task to the working tree as uncommitted edits.

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

The worker needs the `command-code` CLI on `PATH`, signed in with `command-code login`. The Sol review needs the `codex` CLI on `PATH`, signed in to an account that can reach `GRUNT_REVIEW_MODEL`.

Cursor and OpenCode need no install step. The plugin skills are linked into `.cursor/skills`, `link.sh sync` fans them out to the agent config directories, and OpenCode discovers `opencode/plugins/grunt` from the linked config directory.

## Config

Set in `~/.claude/settings.json` under `env`:

| Var | Default | Meaning |
|---|---|---|
| `GRUNT_MIN_LINES` | `1000` | Block reads above this line count |
| `GRUNT_MAX_BYTES` | `6000` | Cap on shell read stdout; the command runs once and the cut is marked |
| `GRUNT_MODEL` | unset | bulk-read model; unset uses your configured `command-code` model |
| `GRUNT_CODER_MODEL` | `deepseek/deepseek-v4.1-flash-fast` | code-write model |
| `GRUNT_REVIEW_MODEL` | `gpt-6.2-sol` | Sol's codex model |
| `GRUNT_FALLBACK_MODEL` | `deepseek/deepseek-v4.1-flash` | review model when Sol fails, run at high effort |
| `GRUNT_SANDBOX` | `1` | macOS OS sandbox fencing worker writes to the worktree |
| `GRUNT_OFF` | unset | `1` disables the read guard |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

`GRUNT_MODEL` and `GRUNT_CODER_MODEL` are `command-code --list-models` names. An unset `GRUNT_MODEL` uses your configured `command-code` model. `GRUNT_REVIEW_MODEL` is a codex CLI model name.

## The editing worker's reach

An editing worker runs with `--yolo`, so a permission prompt never stops it, and it can run any shell command the deny list does not name.

- `GRUNT_DENY` in `lib.sh` lists the commands the worker may not run. The worker carries that list in its own `.commandcode/settings.local.json`, so `code-write` needs no install in your tree. A denied call comes back to the worker as a refusal, not a prompt.
- A deny rule wins over `--yolo` and over any allow rule, and Command Code matches it against each subcommand of a chain, so `cd x && rm y` is still refused. A wrapper such as `bash -c 'rm y'` or a full path sits outside what the rule can see.
- A deny rule sees commands and tools, not shell redirects, so it cannot keep a worker inside the worktree: `echo x > ~/notes` passes every rule. On macOS, `sandbox-exec` supplies that fence, denying every write outside the worktree and the temp paths in `GRUNT_SANDBOX_RW`. Other platforms run unfenced, so the spec and the diff read carry the boundary. Keep the spec tight and read the diff.

A reading worker runs with `--permission-mode dont-ask`: read-only tools run, and anything that would need approval is denied.

Neither mode is a read fence: a worker reads whatever you can read.


## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out  backend
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

Guard rows stop after `bytes`: `blocked-bulk` and `blocked-generated` from the whole-file rule, `capped-read` from the shell cap. For `capped-read`, `lines` and `bytes` are the estimate from the command, not the truncated output.

## Limits

Delegation covers understanding, not editing, debugging, or design decisions. Each skill lists when not to use it.
