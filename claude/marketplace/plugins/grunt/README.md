# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model (DeepSeek V4.1 Flash through `opencode`).

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** makes Claude the planner and reviewer. Claude writes a spec for each step. The worker runs as an `opencode` agent in a git worktree, edits files, and loops on a check command. Claude reviews each step's diff, and `finish` applies the whole task to the working tree as uncommitted edits.

A `PreToolUse` hook routes reads: whole-file reads over `GRUNT_MIN_LINES` (default 350) are blocked with a pointer to the skill, and generated files (lockfiles, minified assets, `node_modules`, `dist`) are blocked with a "use rg" message. Targeted reads (`offset`/`limit`) and piped shell reads pass through.

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
| `GRUNT_MODEL` | `opencode-go/deepseek-v4.1-flash#low` | bulk-read model |
| `GRUNT_TIMEOUT` | `120` | Seconds per bulk-read call |
| `GRUNT_CODER_MODEL` | `opencode-go/deepseek-v4.1-flash#high` | code-write model |
| `GRUNT_CODER_TIMEOUT` | `540` | Seconds per code-write step, under Claude's 600s Bash limit |
| `GRUNT_OFF` | unset | `1` disables the read guard |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

## Limits

Delegation covers understanding, not editing, debugging, or design decisions. Each skill lists when not to use it.
