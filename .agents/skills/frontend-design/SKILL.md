---
name: frontend-design
description: Creates distinctive, production-grade frontend interfaces with high design quality. Must always apply when building web components, pages, applications, or styling any web UI (websites, landing pages, dashboards, React components, HTML/CSS layouts). Produces creative, polished code that avoids generic AI aesthetics. Also applies when writing interface copy: eyebrows, echo subheads, helper text that restates a label.
license: Complete terms in LICENSE.txt
---

# Frontend Design

Approach this as the design lead at a design studio known for giving every client a distinct visual identity that is not mistaken for anyone else's. This client has already rejected proposals that felt cliché or templated, and is paying for a distinctive point of view: make deliberate, opinionated choices about palette, typography, and layout that are specific to this brief, and take aesthetic risk if justified.

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

**Ground your designs in the subject matter.** If the brief does not identify what the product or subject matter is, identify it yourself before designing, and confirm with the client. You can come up with one concrete subject, the design's audience, and the design's primary job, as a proposal. If your memory holds preferences or context about what the client is building, use that as a hint. The subject's industry, subject matter, materials, and vernacular are where distinctive visual choices come from. A design for a toy for girls aged 8-11 will be very aesthetically different from a dashboard for financial analysts. Build with the brief's real content and subject matter throughout.

## Aesthetics Guidelines

- **Typography**: Choose distinctive, characterful fonts. Avoid generic choices (Arial, Inter). One family or two, and if two, make them clearly distinct. Choose typefaces deliberately, not the default families you would reach for on any other project, and set a clear type scale following the default guidance of The Elements of Typographic Style with intentional weights, widths, and spacing. When type is used as a headline or visual element, use the type treatment itself as an active part of the design, not a neutral delivery vehicle for the content. Default to line lengths of less than 80 characters. Serif typefaces can run slightly longer; give serif body text slightly more line-height than a sans-serif.
- **Color & theme**: Commit to a cohesive aesthetic. Use CSS variables. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Use animations for effects and micro-interactions. Prefer CSS-only for HTML; use the Motion library for React when available. Use non-user-triggered motion sparingly and deliberately, only to draw attention. A single orchestrated moment, one page-load sequence or one reveal, lands better than scattered effects. Fade-and-slide-up entrances on each section and hover transitions on every card are the generic default and read as AI-generated. Motion that answers a person's action (opening, expanding, confirming) is welcome when it shows what changed.
- **Spatial composition**: Unexpected layouts. Asymmetry, overlap, diagonal flow, grid-breaking elements. Generous negative space or controlled density.
- **Backgrounds & visual details**: Create atmosphere and depth. Add contextual effects and textures: gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, decorative borders, custom cursors, grain overlays.
- **The hero**: For web designs, the hero is the first thing viewers will see. Open with the most characteristic thing in the subject's world, in the form that is most appropriate: a headline, an image, an animation, a live demo, an interactive moment, or another treatment. A big number with a small label, supporting stats, and a gradient accent is the default treatment, so only use it if that is truly the best option.
- **Structure is information**: Structural devices like outlines, borders, numbering, eyebrows, dividers, and labels encode useful information about the content rather than decorate it. Numbered markers (01 / 02 / 03) only suit content that really is a sequence, like a stepped process or a timeline.

**Avoid**: Generic AI aesthetics. Overused fonts (Inter, Roboto, Arial, system fonts), clichéd color schemes (purple gradients on white), predictable layouts, cookie-cutter patterns. Do not converge on common choices (e.g. Space Grotesk) across generations. Likewise avoid these default typographic treatments:

- Accenting a single word or phrase in a headline with italic, bold, or a different color.
- All caps for labels.
- Typographic labels above content that add nothing.

**Match complexity to vision**: Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful spacing, typography, and subtle details. Execute the vision well.

Interpret creatively and make unexpected choices that feel designed for the context. No two designs should be the same.

## Process

Work in two passes. First, brainstorm a short design plan based on the brief: create a compact token system with color, type, layout, and principles.

- Color: describe the core base palette as 4-6 named hex values.
- Type: the typefaces and their roles.
- Layout: a layout concept, using one-sentence prose descriptions and ASCII wireframes to ideate and compare. Include alignment guidance: should the content be left aligned, center aligned, justified?
- Principles: the high-level guidance for what makes this page unique.

Then review that plan against the brief before building. Work through a similar prompt to see whether you arrive somewhere similar. If any part of the plan reads like the generic default you would produce for any similar page rather than a choice made for this specific brief, revise that part, say what you changed and why. Only after you have confirmed the relative uniqueness of the plan should you start writing code, following the revised plan.

When writing the code, be careful with CSS selector specificity. It is easy to generate classes that cancel each other out, especially with a type-based selector like `.section` and an element-based selector like `.cta`. This shows up most often in padding and margin between sections.

## Restraint and self-critique

Spend your boldness in one place. Let one element be the memorable thing, keep everything around it quiet and disciplined, and cut any decoration that does not serve the brief. Build to a quality floor without announcing it: responsive down to mobile, visible keyboard focus, reduced motion respected, visually accessible, harmonious color palettes.

Critique your own work as you build, taking screenshots to review if your environment supports it, because a picture is worth 1000 tokens. Chanel's advice applies: before leaving the house, take a look in the mirror and remove one accessory. If you have a place to jot down notes about what you have tried, use it, so later passes do not repeat the same direction.

## Interface copy

Words appear in a design for one reason: to make it easier to understand and use. They are design content, not decoration. Bring the same intentionality and minimalism to copy that you bring to spacing and color. Before writing anything, ask what the design needs to say and how best to say it so the person can navigate the experience.

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

### Writing in design

Write from the end user's perspective. Name things by what users will understand in simple language, not by how the system is built. A user manages notifications, not webhook config. Describe what something is or does in plain terms rather than selling it. Being specific and legible to new users beats being clever.

Use active voice as the default. A CTA says exactly what happens when it is used: "Save changes", not "Submit". An action keeps the same name through the whole flow, so the button that says "Publish" produces a toast that says "Published". The vocabulary of an interface is the signposting for someone navigating the product. Cohesion and consistency are how people learn their way around.

Treat failure and emptiness as moments for direction, not mood. Explain what went wrong and how to fix it, in the interface's voice rather than a person's. Errors do not apologize, and they are never vague about what happened. An empty screen is an invitation to act.

Keep the tone conversational: plain verbs, sentence case, no filler, with tone matched to the brand and the audience. Let each written element do exactly one job.
