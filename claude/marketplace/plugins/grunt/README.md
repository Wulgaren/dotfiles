# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model (`opencode-go/deepseek-v4.1-flash#low` by default).

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** generates boilerplate from a reference file and writes it to disk. The generated code never enters the main model's context.

A `PreToolUse` hook enforces the first path: whole-file reads over `GRUNT_MIN_LINES` (default 350) are blocked with a pointer to the skill. Targeted reads (`offset`/`limit`), piped shell reads, and files under the threshold pass through. Generated files (lockfiles, minified assets, `node_modules`, `dist`) are blocked with a "use rg" message instead.

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
| `GRUNT_MODEL` | `opencode-go/deepseek-v4.1-flash#low` | Worker model |
| `GRUNT_TIMEOUT` | `120` | Seconds per worker call |
| `GRUNT_OFF` | unset | `1` disables the read guard |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

## What it cannot do

The worker misses subtle problems (thread safety, edge cases) and its line numbers drift. Delegation covers understanding, not editing, debugging, or design decisions. The guard lets targeted reads through for that reason.
