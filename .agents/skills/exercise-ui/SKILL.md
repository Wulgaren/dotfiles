---
name: exercise-ui
description: >
  Exercise a web UI with local Playwright after a big UI change (new screen,
  layout, composition, redesign) or when the result is hard to trust without
  seeing it (overflow, stacking, responsive breakpoints, motion, focus).
  Prefer the repo's Playwright specs, then a local install, then a /tmp script.
  Open the running page, drive the flow just changed, capture evidence, and fix
  what you see.
---

# Exercise UI

_Exercise_ the path in a real browser when the change is big enough that layout or composition could be wrong, or when correctness depends on pixels, stacking, overflow, breakpoints, or motion the source cannot prove. The running page is the evidence. Drive it with Playwright installed on this machine.

Write a Playwright test into the repo only when the user asks for one.

## Steps

1. **Name the flow and the URL.** The flow is the user path you changed, not the whole app. The URL is this repo's running page for that path. Reuse a server already serving it; otherwise start the repo's existing dev command and wait until the URL loads. Done when you can name both, or you have reported there is no URL to open.

2. **Pick how to drive Playwright (repo → local → tmp).** In order:
   1. **Repo.** If the project already has Playwright specs that cover this flow, run those (`npx playwright test …`, or the repo's package script). Use the project's config and browsers.
   2. **Local.** If no covering specs exist, find Playwright already on the machine: the project's `node_modules/@playwright/test` or `playwright`, a global install, or `npx playwright` that resolves without adding packages to the repo. Browsers live in the global cache (`~/Library/Caches/ms-playwright` on macOS). Point at that cache; do not run `npx playwright install`, add Playwright packages, or download browsers into the project.
   3. **Tmp.** Write a short throwaway script under `/tmp` that uses that local Playwright to open the URL, drive the flow, and write a screenshot (and any console/DOM notes you need). Delete the script when done.
   Done when you have a concrete command that will run against the URL, or you have reported that no local Playwright is available and stopped.

3. **See the page.** Run the chosen command. Confirm the page loaded (screenshot, test output, or script log). Done when you have looked at the running page, not the source.

4. **Drive the flow.** Click, fill, and navigate the path you changed, the way a user would. Capture after the interesting step. Visual-only changes (spacing, color, type): looking at the page is the flow. Responsive layout: resize and look again. Done when every step of that flow has been performed in the browser.

5. **Fix what you see.** If the screenshot or run output is wrong, change the code, then _exercise_ from the URL again. Done when the last capture matches the intended UI, or you have named a blocker (auth you cannot pass, missing URL, Playwright missing on the machine).
