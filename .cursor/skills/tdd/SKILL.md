---
name: tdd
description: >
  Write tests before code for features, bug fixes, and refactors. Use when
  implementing or refactoring logic, APIs, validation, or data transforms;
  when the user says test-first or TDD; or when AGENT.md says tests come first.
  Grill what to test first; one failing test, then just enough code to pass it,
  then the next behaviour. Skip config, wiring, and glue with nothing to check.
---

# TDD

Write tests first, then code. One behaviour at a time: failing test, then the smallest code change that passes it. For refactors, lock current behaviour in tests before you move code around.

Prove the change. Do not pad the suite. See AGENT.md **Focused tests**.

## When to use this

| Situation | Use test-first? |
|-----------|-----------------|
| Business logic, validation, data transforms, API request/response rules | Yes |
| Bug fix where output is visibly wrong | Yes |
| Refactor that must not change what users see | Yes (capture current behaviour in tests first) |
| Config, env vars, wiring, type-only edits, plain CRUD pass-through | No |
| No way to know the right answer except copying the code | No (the test would be useless) |
| Browser / Playwright / full-app tests | Only if grill-me settled on it, or the user asked |

Not sure if testing is worth it? Run one grill-me round: "is this worth a test?" with what the user would see or get, not internal labels.

## Steps

1. **Grill what to test.** Before creating any test file, run grill-me on open test questions:
   - Where will the test call in? (the public function, HTTP handler, component prop, CLI command, not private helpers inside)
   - What should the user or caller actually get? (outcomes, not "this internal function was called")
   - Where does the expected answer come from? (spec, a hand-worked example, a fixed literal, not running the same logic as the code under test)
   - What gets mocked? (only outside world: APIs, clock, randomness, database when you cannot run a real one locally)
   - Unit test vs integration vs browser? (default: the fastest level that still catches the bug)
   Done when you and the user agree on what to test and what to skip.

2. **Say where you'll test and wait.** One sentence: "I'll test by calling X and checking Y." Do not write tests until the user confirms (or picked your recommendation in grill-me).

3. **Write one failing test.** One behaviour. Name it for the outcome ("rejects empty email"), not the internals ("calls validateEmail"). Run it. It should fail because the feature is missing, not because of a typo in the test. Done when one test fails for the right reason.

4. **Write code to pass.** Only enough production code to make that test green. Do not build ahead for the next test. Done when the test passes.

5. **Next behaviour.** Repeat steps 3–4 for the next thing you agreed to test. Do not write a pile of tests first and code later. Done when every agreed behaviour has a passing test, or was explicitly skipped.

6. **Do not edit tests without asking.** After tests are agreed, they are the contract. Change production code to pass them. To change, delete, or add tests: stop and confirm with the user. Exception: the test is clearly broken (wrong place, copies the implementation, bad setup). Still confirm unless the user said "fix the tests".

7. **Run the flow and checks.** Exercise the real user path. Run the repo's normal checks (typecheck, lint, test). Done when both pass.

Do refactoring in a separate pass or review, not squeezed into step 4.

## Tests you should not add

Do not add tests that do not prove this change.

**Skip or cut:**
- Big smoke suites, regression nets on unrelated features, or "while we're here" coverage unless the user asked
- Expected value built the same way as the code (the test can never catch a real bug)
- Test breaks when you rename an internal function but behaviour is unchanged; mocks of your own modules; checking call counts
- Every edge case when grill-me already picked a smaller set
- Getters, trivial pass-through, framework defaults, glue with no known correct answer
- Playwright before the behaviour works in a fast local test (exercise-ui: browser tests only when the user asks)

**Prefer:**
- One test per agreed behaviour at the level you picked
- Fixed literals and answers from the spec or a worked example
- Real code where cheap; mock only what you cannot run locally (python/typescript best-practices)

**Refactor with no behaviour change:** keep existing tests green. Add a test only if nothing already checks the behaviour you are about to move.

## Bad patterns

| Bad pattern | How you notice it |
|-------------|-------------------|
| Tests internals | Fails on rename though users see the same thing; mocks your own modules |
| Test copies the code | Expected answer computed the same way as the implementation |
| All tests first, code later | Many tests land before any implementation |
| Needless | Does not prove this change, or repeats what another test already checks |

## Done when

You agreed where to test, each agreed behaviour has a passing focused test (or was skipped on purpose), production code passes them, you did not edit tests after agreement without confirming, and the user flow plus repo checks pass.
