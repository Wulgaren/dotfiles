---
name: python-best-practices
description: Python best practices. Must always apply when reading or editing any .py file.
---

# Python best practices

Target Python 3.11+. Prefer the smallest shape that keeps illegal states unrepresentable.

| Rule | Summary |
|------|---------|
| `NewType` brands | Brand distinct primitives (`UserId = NewType("UserId", str)`) so they can't be mixed. Validate once at creation. |
| `Protocol` over ABC | Prefer structural `Protocol` when callers only need a shape. Use ABC when you own the hierarchy and need shared impl. |
| Discriminated unions | Model variants with a `Literal` discriminant (`kind`) on dataclasses or `TypedDict`s. No optional-field bags. |
| Simplest total type | Keep `list[T]` while every operation stays total. Strengthen (`tuple[T, *tuple[T, ...]]`, a parse step) only where `list[T]` forces a lie or a "should never happen" raise. |
| `object` over `Any` | External data is `object` (or untyped until parsed). `Any` disables checking everywhere it touches. |
| No bare `cast` | Every `cast` is a runtime crash waiting. Cast only after validation. Prefer parsers that return the real type. |
| Narrowing hierarchy | Discriminant match/`if` > `isinstance` / `match` > `TypeGuard`/`TypeIs` > `cast`. |
| Type guards | Must verify the claim. A lying `TypeGuard` is worse than `cast`. Name them `is_x` / `has_x`. |
| Exhaustiveness | `assert_never(x)` in the unmatched branch so a new variant fails typecheck. |
| Boundary validation | Validate where data crosses in (JSON, env, HTTP, DB rows); trust types inside. Don't re-validate deep in the call chain. |
| Schema-derived types | Derive from the schema/ORM/OpenAPI types you already have before declaring a parallel model. |
| Keyword args | Prefer keyword-only or a small dataclass/TypedDict for multi-arg calls. Skip on tight hot loops. |
| Fail loud | Required paths raise or return a typed error. Soft defaults (`or ""`, catching everything) stay on true domain optionals. |
| Dataclass for data | `@dataclass(frozen=True)` (or `NamedTuple`) for data. Plain functions for behavior. Inheritance last. |
| `pathlib` | `Path` over `os.path` string surgery. |
| Context managers | Own resources with `with` / `contextlib`. No bare `open` without a clear close path. |
| Composition | Compose callables and small types. Deep class hierarchies and "base service" gods stay out. |
| Modules as singletons | Module-level state is already process-wide. Don't invent a Singleton class. |
| Real tests | Don't mock what you can run. Prefer pytest against real units; mock only I/O you can't host locally. |
| Structured telemetry | Prefer a structured logger with enough context to debug from an id. No stray `print` in shipped code. |
| Async: don't block | No `time.sleep`, sync HTTP, or heavy CPU on the event loop. Offload or use async APIs. |
| Async: structured tasks | Prefer `asyncio.TaskGroup` (or equivalent) over fire-and-forget `create_task` without supervision. |
| Async: cancel-safe | Cleanup in `finally` or context managers so cancellation still releases resources. |

Examples and curated design patterns: `references/patterns.md`.
