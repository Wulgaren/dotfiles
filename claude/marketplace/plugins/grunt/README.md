# grunt

Routes the expensive, low-thinking parts of Claude Code work to a cheap worker model through the `command-code` CLI. The worker is a separate headless Command Code agent, so it does not depend on whichever provider the main session runs on. It reads the project's `CLAUDE.md` and `AGENTS.md`, and picks up the project's `.commandcode` settings when the working directory has one.

Two paths:

- **bulk-reader** sends files to the worker and returns a bullet answer. The files never enter the main model's context.
- **code-writer** makes Claude the planner and reviewer. Claude writes a spec for each step. The worker runs as an agent in a git worktree, edits files, and loops on a check command. Each step is gated on its check. When the series is done, Claude reads the whole task diff. One review pass (GPT-6.2 Sol through `codex`) runs only when the skill says the task is review-worthy: behaviour/API/data risk, multi-file structure, weak checks, or a planner-requested second opinion. When Sol is missing, signed out, or out of credits, the same review runs on Command Code's `deepseek/deepseek-v4.1-flash` at high effort. Presentation/CSS/copy/config that already passed its check skips the review after the planner's own diff read. Planner self-fixes then finish without a second review; a worker continue gets at most one more. The script enforces that: a third `review` for a task is refused, and so is a repeat with no new commits since the last one. `abort` kills an in-flight review. `finish` applies the task to the working tree as uncommitted edits.

The read guard runs in Claude Code. The plugin's `hooks/hooks.json` wires `guard-read` into `PreToolUse`, and its `skills/` carries bulk-reader and code-writer. `link.sh` fans those skills out to `~/.agents/skills`, so Command Code loads them too.

A `PreToolUse` hook routes reads two ways. Whole-file reads over `GRUNT_MIN_LINES` (default 1000) are blocked with a pointer to the skill, and generated files (lockfiles, minified assets, `node_modules`, `dist`) are blocked with a "use rg" message. Targeted reads (`offset`/`limit`) pass through.

Shell output is capped at `GRUNT_MAX_BYTES` (default 6000). The hook rewrites the command so it still runs once, keeps the first 6000 bytes of stdout, saves the full output in the session scratchpad, and appends a marker with the full size and the file path. stderr and the exit code pass through unchanged. It covers read-shaped commands (`sed -n 100,260p f`, `cat a; head -n 40 b`) and commands that dump text (`rg`, `find`, `git`, tests, logs, `npm`). Read-shaped commands come back with `permissionDecision: allow`; every other capped command is only rewritten, so the normal permission flow still applies. Commands that stream indefinitely (`tail -f`, `--watch`, background jobs) are left alone.

Leading `NAME=value` assignments are stripped before a command is classified, so `FOO=1 git diff` is capped like `git diff`. Two forms still slip past: a quoted assignment with a space (`FOO='a b' git diff`) and an `env` prefix (`env FOO=1 git diff`).

## Install

```
claude plugin marketplace add ~/.claude/local-marketplace
claude plugin install grunt@natios
```

The marketplace lives in this dotfiles repo under `claude/marketplace` and is linked to `~/.claude/local-marketplace`.

The worker needs the `command-code` CLI on `PATH`, signed in with `command-code login`. The Sol review needs the `codex` CLI on `PATH`, signed in to an account that can reach `GRUNT_REVIEW_MODEL`.

The plugin skills are symlinked into `.agents/skills` and fanned out to `~/.agents/skills` by `link.sh sync`, so Command Code reads the same two skills.

## Config

Set in `~/.claude/settings.json` under `env`:

| Var | Default | Meaning |
|---|---|---|
| `GRUNT_MIN_LINES` | `1000` | Block reads above this line count |
| `GRUNT_MAX_BYTES` | `6000` | Cap on capped command stdout; the full output stays on disk and the cut is marked |
| `GRUNT_MODEL` | unset | bulk-read model; unset uses your configured `command-code` model |
| `GRUNT_CODER_MODEL` | `deepseek/deepseek-v4.1-flash-fast` | code-write model |
| `GRUNT_REVIEW_MODEL` | `gpt-6.2-sol` | Sol's codex model |
| `GRUNT_FALLBACK_MODEL` | `deepseek/deepseek-v4.1-flash` | review model when Sol fails, run at high effort |
| `GRUNT_SANDBOX` | `1` | macOS OS sandbox fencing worker writes to the worktree |
| `GRUNT_OFF` | unset | `1` in the environment disables the read guard; prefixing a command with `GRUNT_OFF=1` skips the cap for that call |
| `GRUNT_LOG` | `~/.claude/grunt.log` | Usage log |

`GRUNT_MODEL` and `GRUNT_CODER_MODEL` are `command-code --list-models` names. An unset `GRUNT_MODEL` uses your configured `command-code` model. `GRUNT_REVIEW_MODEL` is a codex CLI model name.

## The editing worker's reach

An editing worker runs with `--yolo`, so a permission prompt never stops it, and it can run any shell command the deny list does not name.

- `GRUNT_DENY` in `lib.sh` lists the commands the worker may not run. The worker carries that list in its own `.commandcode/settings.local.json`, so `code-write` needs no install in your tree. A denied call comes back to the worker as a refusal, not a prompt. The list names Unix commands and their cmd.exe equivalents (`del`, `erase`, `rd`, `ren`, `move`), because the worker's shell tool is cmd on Windows.
- A deny rule wins over `--yolo` and over any allow rule, and Command Code matches it against each subcommand of a chain, so `cd x && rm y` is still refused. A wrapper such as `bash -c 'rm y'` or a full path sits outside what the rule can see.
- A deny rule sees commands and tools, not shell redirects, so it cannot keep a worker inside the worktree: `echo x > ~/notes` passes every rule. On macOS, `sandbox-exec` supplies that fence, denying every write outside the worktree and the temp paths in `GRUNT_SANDBOX_RW`. Windows has no OS fence; the deny rules stop `rm` and `del` but not redirects, wrappers, or `powershell -Command`. Other platforms run unfenced. The spec and the diff read carry the boundary. Keep the spec tight and read the diff.

A reading worker runs with `--permission-mode dont-ask`: read-only tools run, and anything that would need approval is denied.

Neither mode is a read fence: a worker reads whatever you can read.


## Log

TSV, one row per delegation or block:

```
timestamp  mode  detail  lines  bytes  tokens_avoided  seconds  worker_in  worker_out  backend
```

`tokens_avoided` is `bytes / 4`, a rough stand-in for what the main model would have read.

Guard rows stop after `detail`: `blocked-bulk` and `blocked-generated` from the whole-file rule, `capped-read` and `capped-output` from the cap. Both cap modes leave `lines`, `bytes` and `tokens_avoided` empty, because the cap keeps the output instead of estimating it.

## Limits

Delegation covers understanding, not editing, debugging, or design decisions. Each skill lists when not to use it.
