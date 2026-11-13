---
name: code-writer
description: Generate boilerplate that copies an existing file's patterns and write it straight to disk, so the generated code never enters your context. Use for tests, config stubs, type stubs, and repetitive scaffolding. Not for logic changes, bug fixes, or anything where correctness needs judgment.
---

# code-writer

Sends a spec plus one reference file to a cheap worker model and writes the result to disk. You get a path and a diff stat back, not the code.

## When to use it

- A test file that mirrors a neighbour exactly.
- A config stub, a type stub, a new module that copies an existing one.
- Anything where the output is predictable from a file that already exists.

## When not to use it

- Logic changes, bug fixes, refactors. Use Edit.
- Security, money, migrations, or anything where being subtly wrong is expensive.
- When no reference file is close enough. You will get plausible code that fits nothing.

## Usage

```
${CLAUDE_PLUGIN_ROOT}/scripts/code-write --spec "Tests for UserService, same cases as OrderService" --reference tests/OrderTest.ts --target tests/UserTest.ts
```

- `--reference` is required and must be a real neighbour.
- `--target` writes to disk and refuses to overwrite an existing file unless you pass `--force`.
- Without `--target` the code goes to stdout, which defeats the point and costs you the tokens.
- After writing, run the repo's tests or typecheck on the target. The worker does not.
- State the target path in your reply so the user can open it.

## Config

`GRUNT_MODEL` changes the worker, `GRUNT_TIMEOUT` (default 120s) caps a call. Logs land in `~/.claude/grunt.log`.
