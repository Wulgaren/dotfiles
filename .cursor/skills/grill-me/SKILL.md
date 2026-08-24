---
name: grilling
description: >
  Interview the user about plans, designs, architecture, scope, tradeoffs, or
  implementation strategy before proposing solutions or making edits. Use whenever
  there are open decisions to settle, not just when the user says "grill me".
  Skip only for purely mechanical or factual requests. Must always apply.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled — the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

### Presenting questions

Call `AskQuestion` the same way you call `Read`: it is already in the available tools list. Use it whenever questions have discrete options. Put your recommended answer as the first option with "(Recommended)" appended. Group all frontier questions into a single `AskQuestion` call when possible (multiple pages).

`AskQuestion` is a first-class tool. Invoke it directly. It is not in the `cursor` namespace and is not found via MCP or dynamic-tool discovery.

Each round the user answers reshapes the tree — settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it — don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report — ask the rest of the frontier now. The _decisions_ are the user's — put each to them and wait.

## Distinguishable options

Multiple-choice options must pass the **plain-difference test**: someone who does not know the codebase can still say, in one sentence, what they would *see or get* differently if they pick A vs B vs C.

- Frame options as **product / UX / policy outcomes**, not wiring, algorithms, layout engineering, or skeleton/placeholder mechanics.
- Lead each option with the observable difference. Put implementation detail only after that, and only if it helps.
- If two options would feel the same to the user, or only differ by implementer taste → **do not ask**. Pick one, put it in the ➡️ recommendation, continue.
- If the option set is more technical than the real decision, collapse it to the simpler question the user can actually answer.

**Bad** (opaque interleave mechanics): A) round-robin without Google → Marginalia/Wiby → Brave → Tavily. B) four-way interleave. C) commercial block then non-commercial block.

**Good** (what the list feels like): A) Mix other engines together under Google. B) Commercial results as one block, then indie engines as another block.

**Bad** (layout engineering): A) Split layout; skeleton only covers top row. B) Keep cast in column; accept taller than image. C) Drop cast.

**Good** (what the page looks like): A) Cast under the whole hero so image and text stay equal height. B) Cast stays beside the image (text column may grow taller). C) No cast this pass.

The session is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed. Do not act on it until the user confirms you have reached a shared understanding.
