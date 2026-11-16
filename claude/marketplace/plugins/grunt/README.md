# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model: DeepSeek V4.1 Flash through `opencode`. When DeepSeek runs past its switch time or fails, Cursor's `agent` CLI with the Auto model takes over for the rest of the time limit.

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** makes Claude the planner and reviewer. Claude writes a spec for each step. The worker runs as an agent in a git worktree, edits files, and loops on a check command. Claude reviews each step's diff, and `finish` applies the whole task to the working tree as uncommitted edits.

A `PreToolUse` hook routes reads two ways. Whole-file reads over `GRUNT_MIN_LINES` (default 350) are blocked with a pointer to the skill, and generated files (lockfiles, minified assets, `node_modules`, `dist`) are blocked with a "use rg" message. Targeted reads (`offset`/`limit`) pass through.

Shell reads that the block rule cannot see, such as `sed -n 100,260p f` or `cat a; sed -n 1,140p b`, are capped at `GRUNT_MAX_BYTES` (default 6000). The hook rewrites the command so it still runs once, keeps the first 6000 bytes of stdout, and appends a marker with the full size plus the two ways to get the rest: an exact range or a bulk-read question. stderr and the exit code pass through unchanged. The rewrite returns `permissionDecision: allow`, so a capped command does not go through the permission prompt.

## Install

```
claude plugin marketplace add ~/.claude/local-marketplace
claude plugin install grunt@natios
```

The marketplace lives in this dotfiles repo under `claude/marketplace` and is linked to `~/.claude/local-marketplace`.

## Config

Set in `~/.claude/settings.json` under `env`:

| Var | Default | Meaning |
|---|---|---|
| `GRUNT_MIN_LINES` | `350` | Block reads above this line count |
| `GRUNT_MAX_BYTES` | `6000` | Cap on shell read stdout; the command runs once and the cut is marked |
| `GRUNT_MODEL` | `opencode-go/deepseek-v4.1-flash#low` | bulk-read model |
| `GRUNT_SWITCH_AFTER` | `60` | Seconds before a bulk-read call switches to Cursor |
| `GRUNT_TIMEOUT` | `120` | Seconds per bulk-read call, both workers together |
| `GRUNT_CODER_MODEL` | `opencode-go/deepseek-v4.1-flash#high` | code-write model |
| `GRUNT_CODER_SWITCH_AFTER` | `220` | Seconds before a code-write step switches to Cursor. Cursor then gets the rest of the 540s |
| `GRUNT_CODER_TIMEOUT` | `540` | Seconds per code-write step, both workers together, under Claude's 600s Bash limit |
| `GRUNT_FALLBACK_MODEL` | `auto` | Cursor `agent` model |
| `GRUNT_OFF` | unset | `1` disables the read guard |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out  backend
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

Guard rows stop after `bytes`: `blocked-bulk` and `blocked-generated` from the whole-file rule, `capped-read` from the shell cap. For `capped-read`, `lines` and `bytes` are the estimate from the command, not the truncated output.

## Limits

Delegation covers understanding, not editing, debugging, or design decisions. Each skill lists when not to use it.
