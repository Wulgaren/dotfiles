# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model: OpenCode Go's DeepSeek V4.1 Flash, through the `ocgo` wrapper. `ocgo` starts a headless `claude -p` already pointed at OpenCode Go with its own key, so the worker does not depend on whichever provider the main session runs on. It inherits your CLAUDE.md, hooks and plugins and gets the same tools as the main session.

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** makes Claude the planner and reviewer. Claude writes a spec for each step. The worker runs as an agent in a git worktree, edits files, and loops on a check command. Claude reviews each step's diff. When the series is done, GPT-6.1 Sol (through the `codex` CLI) and the `ocgo` worker review the whole task at once; Sol is optional, so a run that fails or times out is skipped, while a returned `changes-needed` verdict still fails the review. `finish` applies the task to the working tree as uncommitted edits.

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

The worker needs the `ocgo` script on `PATH` (this repo links `scripts/ocgo` into `~/.local/bin`) and an OpenCode Go key in `~/.config/opencode-go/key`. The Sol review needs the `codex` CLI on `PATH`, signed in to an account that can reach `GRUNT_REVIEW_MODEL`.

Cursor and OpenCode need no install step. The plugin skills are linked into `.cursor/skills`, `link.sh sync` fans them out to the agent config directories, and OpenCode discovers `opencode/plugins/grunt` from the linked config directory.

## Config

Set in `~/.claude/settings.json` under `env`:

| Var | Default | Meaning |
|---|---|---|
| `GRUNT_MIN_LINES` | `1000` | Block reads above this line count |
| `GRUNT_MAX_BYTES` | `6000` | Cap on shell read stdout; the command runs once and the cut is marked |
| `GRUNT_MODEL` | `deepseek-v4.1-flash` | bulk-read model |
| `GRUNT_TIMEOUT` | `120` | Seconds per bulk-read call |
| `GRUNT_EFFORT` | `low` | Reasoning effort for the `claude` workers |
| `GRUNT_CODER_MODEL` | `deepseek-v4.1-flash` | code-write model |
| `GRUNT_CODER_TIMEOUT` | `540` | Seconds per code-write step, under Claude's 600s Bash limit |
| `GRUNT_REVIEW_MODEL` | `gpt-6.1-sol` | Sol's codex model |
| `GRUNT_REVIEW_TIMEOUT` | `540` | Seconds for each reviewer, run in parallel |
| `GRUNT_SANDBOX` | `1` | Fence an editing worker's shell writes |
| `GRUNT_OFF` | unset | `1` disables the read guard |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

`GRUNT_MODEL` and `GRUNT_CODER_MODEL` are model names OpenCode Go serves. The worker is launched through `ocgo`, which sets that endpoint, key and model, so it ignores the main session's provider. `GRUNT_REVIEW_MODEL` is a codex CLI model name. The ocgo reviewer runs on `GRUNT_CODER_MODEL`.

## The editing worker's reach

An editing worker runs `acceptEdits` with `Bash` allowed, so a permission prompt never stops it and a shell redirect reaches any path on the machine. `git push` is still refused, but `rm` and friends were not, and a probe run of this plugin wrote straight into the main repository over a redirect. Two things fence that in.

- `GRUNT_DENY` in `lib.sh` lists the commands the worker may not run: `rm`, `mv`, `git push`, `git reset`, `sudo`, and the rest of the ask rules from `opencode.json`. A denied call comes back to the worker as a refusal, not a prompt.
- `--settings` turns on Claude Code's OS sandbox with `allowUnsandboxedCommands: false`, so a worker cannot run a command outside it. Sandboxed shell writes fail with `operation not permitted` anywhere outside the worktree, except a path some settings file already grants.

That exception is why the fence does not rest on the sandbox's default boundary. `sandbox.filesystem` has grants (`allowWrite`) and restrictions (`denyWrite`) but no allow-only list, and `allowWrite` merges grants from user settings, project settings and `Edit` allow rules. A single inherited grant reopens its path. `GRUNT_DENY_WRITE` therefore names paths outright, since `denyWrite` outranks every grant. It holds your SSH, AWS and GPG keys, `~/.claude`, `~/Library`, `~/Documents`, the system prefixes, and the main repository itself — a worker that writes there skips review entirely.

The main repository is the boundary worth testing. With a settings file that granted it explicitly, a probe worker's write was still refused:

```
sandbox.filesystem.allowWrite = ["/private/tmp/grunt-task"]
sandbox.filesystem.denyWrite  includes "/private/tmp/grunt-task"
→ operation not permitted
```

The write fence is not a read fence: a worker can read anything you can, as `claude` itself can.


## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out  backend
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

Guard rows stop after `bytes`: `blocked-bulk` and `blocked-generated` from the whole-file rule, `capped-read` from the shell cap. For `capped-read`, `lines` and `bytes` are the estimate from the command, not the truncated output.

## Limits

Delegation covers understanding, not editing, debugging, or design decisions. Each skill lists when not to use it.
