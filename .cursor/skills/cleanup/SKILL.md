---
name: cleanup
description: >
  Post-green cleanup pass: remove redundancy and dead paths in this change's
  blast radius, reuse existing helpers, keep behaviour green. Use after the
  feature or fix is confirmed working; when the user says cleanup or tidy the
  diff; or when tdd/AGENT.md call for the separate refactor pass after green.
---

# Cleanup

The pass after it works. Shrink the diff. Keep behaviour.

Apply `principle-laziness-protocol` and `principle-subtract-before-you-add` while you work. Do not restate them here.

## Steps

1. **Ask before you touch.** Ask the user if everything is working. If they say no or are unsure, stop and fix or diagnose; do not clean up. If they say yes, say you are starting cleanup and continue. Done when they confirmed yes, or you stopped.

2. **Name the radius.** List the files and symbols this change introduced or replaced. Stay inside that list. Done when the radius is named in one short line.

3. **Hunt deletions first.** Inside the radius, remove: dead code, replaced old paths, duplicate helpers you just added, speculative branches, debug leftovers. Prefer delete over rewrite. Done when nothing in the radius is optional for the behaviour.

4. **Reuse, don't invent.** Grep for an existing helper, hook, or pattern with the same job. If one exists and is sound, import it and delete your copy. If the neighbor pattern is bad, do not copy it; keep the smaller clear version. Done when new code either reuses a sound existing piece or has no existing piece to use.

5. **One path.** One way to do each thing the change owns. No parallel old/new APIs left "just in case." Done when callers use a single path.

6. **Re-prove green.** Re-run the user flow you already exercised and the repo's usual checks. Fix only what cleanup broke. Done when both pass.

## Done when

User confirmed it was working, the radius shrank or stayed flat with no new abstractions, sound existing pieces were reused, one path remains, and checks are still green.
