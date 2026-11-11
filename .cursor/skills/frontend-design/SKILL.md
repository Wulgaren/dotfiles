---
name: frontend-design
description: Creates distinctive, production-grade frontend interfaces with high design quality. Must always apply when building web components, pages, applications, or styling any web UI (websites, landing pages, dashboards, React components, HTML/CSS layouts). Produces creative, polished code that avoids generic AI aesthetics. Also applies when writing interface copy: eyebrows, echo subheads, helper text that restates a label.
---

# Frontend Design

Guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement working code with strong attention to aesthetic detail and intentional creative choices.

## Design Thinking

Before coding, understand the context and commit to a **bold** aesthetic direction:

- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme—e.g. brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian. Use for inspiration but design something true to the chosen direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this memorable? What will someone remember?

**Critical**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work; the key is intentionality.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:

- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Aesthetics Guidelines

- **Typography**: Choose distinctive, characterful fonts. Avoid generic choices (Arial, Inter). Pair a distinctive display font with a refined body font.
- **Color & theme**: Commit to a cohesive aesthetic. Use CSS variables. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prefer CSS-only for HTML; use Motion library for React when available. Focus on high-impact moments—e.g. one well-orchestrated page load with staggered reveals (`animation-delay`) rather than scattered micro-interactions. Use scroll-triggering and hover states that surprise.
- **Spatial composition**: Unexpected layouts. Asymmetry, overlap, diagonal flow, grid-breaking elements. Generous negative space or controlled density.
- **Backgrounds & visual details**: Create atmosphere and depth. Add contextual effects and textures: gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, grain overlays.

**Avoid**: Generic AI aesthetics—overused fonts (Inter, Roboto, Arial, system fonts), clichéd color schemes (e.g. purple gradients on white), predictable layouts, cookie-cutter patterns. Vary between light and dark themes, different fonts, different aesthetics. Do not converge on common choices (e.g. Space Grotesk) across generations.

**Match complexity to vision**: Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful spacing, typography, and subtle details. Execute the vision well.

Interpret creatively and make unexpected choices that feel designed for the context. No two designs should be the same.

## Interface copy

Every string on screen has to tell the reader something they do not already know. Delete the rest. Bad UI text is rarely wrong. It repeats a neighbour, so the fix is deletion rather than a rewrite.

**Delete these:**

- **Eyebrow.** The small label above a heading that restates it. `SETTINGS` over "Settings".
- **Echo subhead.** A line under a heading that says the heading again in a sentence. "Manage your account" under "Account".
- **Restating helper text.** Copy under a field or value that repeats its label or its value. "Email. Enter your email address."
- **Section intro.** A paragraph announcing the list below it before the list has said anything.
- **Self-narration.** Text describing the interface's own structure. "Here you can see all your projects."
- **Echo buttons.** A dialog title repeated as the confirming button, or a button label repeated in the body above it.

The causes are worth naming because each one needs a different fix. Template blanks ship placeholder copy nobody deleted. Narrating your own work treats a screen like a commit message. More text feels more finished, so empty space gets filled. Chat habits ("Great question", "Let me know if you need anything else") leak from assistants into products.

**Keep text here:**

- Field errors and validation, which carry a fact the label cannot.
- Recovery paths: what failed, and what to do about it.
- Destructive confirmations, where the consequence must be spelled out.
- Empty states where the screen is blank and the next action is not obvious.
- Constraints the reader cannot guess: format, limit, timing, cost.

The test: hide the line and read the screen. If nothing is lost it was noise. If something is lost, the label was doing a bad job, so write a better label instead of a helper line under it.
