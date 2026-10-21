---
name: cleanup
description: >
  Cleanup before handoff: remove redundancy and dead paths in this change's
  blast radius, reuse existing helpers, keep behaviour green. Must always
  apply after code edits once the flow and build are green, before handing
  control back. Skip only when this turn had no code edits. Also when the
  user says cleanup or tidy the diff.
---

# Cleanup

The pass after it works and before handoff. Shrink the diff. Keep behaviour.

Apply `principle-laziness-protocol` and `principle-subtract-before-you-add` while you work. Do not restate them here.

## Steps

1. **Gate.** If this turn had no code edits, skip cleanup and say so. Otherwise continue with no ask-first. Done when you skipped with that reason, or you continued.

2. **Name the radius.** List the files and symbols this change introduced or replaced. Stay inside that list. Done when the radius is named in one short line.

3. **Hunt deletions first.** Inside the radius, remove: dead code, replaced old paths, duplicate helpers you just added, speculative branches, debug leftovers. Prefer delete over rewrite. Done when nothing in the radius is optional for the behaviour.

4. **Reuse, don't invent.** Grep for an existing helper, hook, or pattern with the same job. If one exists and is sound, import it and delete your copy. If the neighbor pattern is bad, do not copy it; keep the smaller clear version. Done when new code either reuses a sound existing piece or has no existing piece to use.

5. **One path.** One way to do each thing the change owns. No parallel old/new APIs left "just in case." Done when callers use a single path.

6. **Re-prove green.** Re-run the user flow you already exercised. Then run the same production-style build used before handoff (or the usual gate if there is no build script, and say so). Typecheck or unit tests alone do not replace a production build when one exists. Fix only what cleanup broke. Done when both pass.

## Done when

You skipped because this turn had no code edits, or: the radius shrank or stayed flat with no new abstractions, sound existing pieces were reused, one path remains, and the build or fallback gate is still green. Hand control back only after this.
