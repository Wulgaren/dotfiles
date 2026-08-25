---
name: exercise-ui
description: >
  Exercise a web UI in Playwright after changing it. Must always apply when
  building, restyling, or checking a web UI. Open the running page, snapshot,
  drive the flow just changed, screenshot, and fix what you see.
---

# Exercise UI

After any web UI change, _exercise_ the path in a real browser. The running page is the evidence. Drive it with Playwright browser tools.

Write a Playwright test file only when the user asks for one.

## Steps

1. **Name the flow and the URL.** The flow is the user path you changed, not the whole app. The URL is this repo's running page for that path. Reuse a server already serving it; otherwise start the repo's existing dev command and wait until the URL loads. Done when you can name both, or you have reported there is no URL to open.

2. **Open Playwright.** Discover browser tools with GetDynamicTools (pattern `playwright`). Use a namespace whose `namespaceStatus` is `ready`. Invoke with CallDynamicTool. Done when navigate works, or you have reported Playwright is unavailable and stopped.

3. **See the page.** Navigate to the URL. Snapshot (the tree you act on). Screenshot (what it looks like). Done when you have looked at the running page, not the source.

4. **Drive the flow.** Click, fill, and navigate the path you changed, the way a user would. Snapshot after the interesting step. Visual-only changes (spacing, color, type): looking at the page is the flow. Responsive layout: resize and look again. Done when every step of that flow has been performed in the browser.

5. **Fix what you see.** If the screenshot or snapshot is wrong, change the code, then _exercise_ from the URL again. Done when the last screenshot matches the intended UI, or you have named a blocker (auth you cannot pass, missing URL, Playwright down).
