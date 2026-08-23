# Agent policy

## Workflow

1. **Clarify spaghetti before changing it.** If the area is tangled, has unclear ownership, or shows multiple conflicting patterns, ask how to treat it (minimal surgical fix vs small cleanup vs larger refactor). Done when the user has chosen, or the area is not spaghetti.
2. **Investigate before editing.** Search and read existing helpers, components, hooks, and patterns in-repo. Prefer reuse or extension over new code.
   - Before adding a helper (string normalize, format, parse, URL, toast wrapper, etc.): grep the repo for an existing function with the same job. Check shared utils / lib folders first.
   - If one exists: import and reuse it. Leave the body where it lives.
   - If tests fail because a mock lacks an export: add the export to the test mock. Leave the real helper alone.
   Done when you have reused an existing piece or confirmed none exists for the job.
3. **Verify build after TS/React/CSS work.** Run the project's build or typecheck before claiming done. Fix failures you introduced. If the build is already red from unrelated files, say so and either fix them if cheap or ask before expanding scope. Done when the check passes, or you have reported pre-existing red and settled scope with the user.

## Preferences

- **Least code.** Smallest diff that fixes the root cause. Extend existing patterns before adding abstractions.
- **Readable > clever.** Flat functions, explicit names, one obvious path.

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

Workflow and tooling notes that transfer across projects (search, edits, lint, paths, ambiguity). Project-specific bug fixes and API/UI quirks go in that project's `AGENT.md`, not here.

---

## 1. Search strategy

**Struggle:** Wasting time with the wrong tool or too broad a search.

**Resolution:**
- **Exact symbols/strings** → use `Grep` (e.g. function name, env var, string literal).
- **Meaning / "how does X work?"** → use `SemanticSearch` with a clear question and, if known, a target directory.
- **File by name** → use `Glob`; **directory layout** → use `LS`.
- Start with one focused search; narrow by directory or file if the codebase is large.

---

## 2. Failed search_replace (old_string not unique)

**Struggle:** Edit fails because `old_string` matches in several places or the match is ambiguous.

**Resolution:**
- Include more **context** (3–5 lines before and after) so the match is unique.
- For **renames or repeated tokens**, use `replace_all: true` only when every occurrence should change.
- Re-read the file around the target line to get exact whitespace and content.

---

## 3. Large files

**Struggle:** Reading a huge file is slow and noisy; easy to miss the right spot.

**Resolution:**
- Use `SemanticSearch` or `Grep` in that file to find the relevant section, then `Read` with `offset` and `limit`.
- Prefer editing a small, unique span of lines rather than the whole file.

---

## 4. Parallel vs sequential tool use

**Struggle:** Doing independent work one step at a time slows things down.

**Resolution:**
- Call **independent** tools in parallel (e.g. multiple `Read` or `Grep` that don't depend on each other).
- Use **sequential** calls when one result informs the next (e.g. search → then read the found file).

---

## 5. Linting and errors after edits

**Struggle:** Introducing regressions or lint errors that aren't obvious.

**Resolution:**
- After editing a file, run `ReadLints` on that file (or the edited directory).
- Fix any new errors before moving on; don't assume the edit was safe.

---

## 6. Multi-step and ambiguous tasks

**Struggle:** Forgetting steps, or solving the wrong thing when the request is vague.

**Resolution:**
- For **multi-step or complex work**, use a todo list: break into concrete steps and tick them off.
- If the request is ambiguous (e.g. "fix it", "make it better"), **infer from context** (open files, recent edits, errors). If still unclear, ask one short, specific question rather than several.

---

## 7. Paths and runlists

**Struggle:** Commands or reads failing due to wrong path or environment.

**Resolution:**
- Prefer **absolute paths** when the user or workspace root is known (e.g. `/Users/natios/...` or workspace path).
- For **run scripts / dev servers**: use the project's package manager and scripts (e.g. `bun run dev`); check `package.json` or project rules for the right commands.

---

## 8. Reading the right thing

**Struggle:** Editing or reasoning from an outdated or wrong part of the file.

**Resolution:**
- After a prior read, if the file might have changed or the relevant section wasn't in the snippet, **re-read** the exact range before editing.
- Use **citations** with line numbers (e.g. `12:15:path/to/file`) so the referenced region is clear.

---

*Add an entry here only when the struggle and fix would help in an unrelated repo. Otherwise use the project's own AGENT.md, or skip.*
