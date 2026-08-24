# Agent policy

## Workflow

1. **Name the _target_.** Point at the existing widget, command, or code path you will change, and the _blast radius_ (what you may touch). If either is unclear, ask. Several decisions hanging off it: use grill-me. Spaghetti (tangled ownership, conflicting patterns): ask surgical vs cleanup vs refactor before editing. Stay inside the named radius. Done when the target and radius are named, or the user has answered.

2. **Investigate before editing.** Search and read existing helpers, components, hooks, and patterns. Reuse or extend them.
   - Before adding a helper: grep for one with the same job. Shared utils / lib first.
   - If one exists: import it. Leave the body where it lives.
   - If tests fail because a mock lacks an export: add the export to the mock. Leave the real helper alone.
   Done when you have reused an existing piece or confirmed none exists.

3. **_One path_.** Change the existing path. Remove the old helper, backdrop, global, or branch in the same change. Done when there is a single way to do the thing.

4. **_Instrument_ when the cause is unknown.** Add a log or probe, reproduce, read the output, then fix. Revert a speculative rewrite before the next guess. Done when the failing signal is visible, or the fix is the observed cause.

5. **Smallest diff.** Fix the root cause with the least new code. Extend an existing pattern before adding an abstraction. Done when nothing in the diff is optional for the target.

6. **_Exercise_ the path, then check.** Click or run the actual user flow (the widget, the command, the URL). Typecheck is not that step. Then run that repo's usual check (typecheck, lint, test, hooks). Fix what you introduced. If the check was already red from unrelated files, say so and settle scope before expanding. Done when the flow works and the check passes, or you have reported pre-existing red and settled scope.

## Preferences

- **Readable > clever.** Flat functions, explicit names, one obvious path.
- **Questions are read-only.** When the user asks what, why, or how something works, investigate and answer. Edit only when they ask for a change.
- **Comments.** Describe how a function, class, or type is used, above its definition. Skip line-by-line narration. When behavior changes, update or remove the comment in the same edit.
- **Focused tests.** Prefer tests that prove the change. Skip broad smoke suites and regression nets around unrelated features or deletions unless asked.
- **YAGNI.** Prefer the smallest model that makes the correct behavior unsurprising. When tempted to add abstractions, layers, or speculative machinery, follow the laziness and subtract-before-you-add skills.

## TypeScript: no `any`

- Prefer `unknown` + narrowing, proper types, or Zod-inferred types over new `any`.
- When touching a line that already uses `any`, replace it if cheap. Leave unrelated legacy `any` alone.
- Zero `any` in new React/frontend code.
- Prefer a single boundary cast with a comment over `as any` escape hatches when a cast is unavoidable.

## Negative space programming

Prefer explicit failure over silent absence. Make invalid or missing required data loud. Required paths throw, return a typed error, or surface an error state. Soft defaults and optional chaining stay on true domain optionals.

### Strictness by area

| Area | Mode | Rule |
|------|------|------|
| React / frontend components | **A (hard)** | Almost never use `?.` / soft defaults on data you own. Null/undefined on a required path → throw, typed error, or React Query / UI error state. `?.` only for true domain optionals (e.g. middle name, optional avatar). |
| Backend / services / APIs | **A (hard)** | Same: required contracts fail explicitly. Missing values stay visible; null-forgiving and catch-and-ignore stay off those paths. |
| Legacy scripts / glue | **B (prefer fail-loud)** | Default: check + throw/handle on required paths and network results. Allow `?.` when absence is normal for DOM/legacy glue (optional nodes, maybe-missing nested legacy fields). |

### Fallible operations (fetch, I/O, parsing)

When adding `fetch`, other network calls, file/I/O, or parsing that can fail, even if the user did not ask for error handling:

- Handle failure in code: throw, return a Result-like failure, or let React Query own `isError` / `error`.
- Every `await fetch(...)` (or equivalent) gets a failure path.
- Add visible error UI (toast, inline message, error boundary content) only when the feature already has an error surface or the user asked for it. Leave full error UX for those cases.

### Anti-patterns

- Long optional chains on required data: `user?.profile?.name?.toUpperCase()`
- Catch blocks that swallow errors (`catch { return null }` / empty `catch`) without a deliberate, documented recovery
- Defaulting required IDs/config with `||` / `??` in a way that hides a missing value

### Validation pattern

- Parse external data before using it in components.
- Prefer tolerant schemas for legacy endpoints when the UI can recover safely, for example coercing numeric strings and normalizing `null` strings to `""`.
- Fail fast for programmer errors and security-sensitive shapes; fall back only for optional UI data. Aligns with mode **A** in React: optional UI fields may soft-fall back; required shapes must not.

---

# Agent learnings: struggles and resolutions

Workflow and tooling notes that transfer across projects. Project-specific bug fixes and API/UI quirks go in that project's `AGENT.md`, not here.

---

## 1. First-class tools vs MCP / dynamic tools

**Struggle:** A skill names a first-class tool (`AskQuestion`, `Read`, `Grep`) and the agent hunts for it with `GetDynamicTools` / `CallDynamicTool` (often namespace `cursor`), then fails because the tool is already in the available tools list.

**Resolution:**
- Invoke first-class tools directly, same as `Read`.
- Use `GetDynamicTools` / `CallDynamicTool` only for tools that are *not* already listed as available.
- The `cursor` dynamic namespace is extra tools (`CreateGoal`, `GenerateImage`, `UpdateGoal`), not the main tool list.
- When writing a skill, say "call X the same way you call Read" rather than "harness built-in" or "MCP".

---

*Add an entry here only when the struggle and fix would help in an unrelated repo. Otherwise use the project's own AGENT.md, or skip.*
