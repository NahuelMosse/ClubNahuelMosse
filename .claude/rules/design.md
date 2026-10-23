---
paths: ["**/*.css", "**/*.tsx", "**/*.jsx", "**/*.vue", "**/*.svelte", "**/*.html"]
---

# Design: the level of a screen comes from the process, not from the model

Loads by itself when you touch a screen file. It applies to product screens (forms, CRM, dashboards) and to landings. A
repo with its own design system uses it: where this rule names a font, token or curve, the repo's wins. The card's `## Look`
(`ref:`, `behavior:`, `tokens:`) is the brief; this is how it is built.

## Before
- Build against the `ref:` of `## Look`: copy its system (hierarchy, density, depth, motion), not its pixels.
- The reference sets the level (quality, depth, motion, type); the composition is yours. `## Direction` names 3 layout decisions that differ from it.
- One visual direction in two lines (tone, density, a memorable trait). One focal point per screen.

## Tokens, in one place
- Colors, fonts, spacing, radii, shadows, easings and durations are CSS variables or the theme file. No loose value in a component.
- The `tokens:` of `## Look` picks a display font with character, from Google Fonts or the repo's; never only the system font.
- Two font families with character, one for display and one for text. Never Inter, Roboto, Arial or the system font as identity.
- Six to eight font sizes in a fixed scale; at most three weights.
- Spacing on a scale (4 8 12 16 24 32 48 64 96); no margin or padding outside it.
- Two or three radii and two or three layered, tinted shadow levels. No pure `#000` or `#fff`.

## Motion: every control answers
- Hover, press, focus-visible and success each have their own response, on every button, link, field, row and switch.
- Two or three easings with their duration, defined once: `out` 200 to 300 ms, `pop` or spring 400 to 500 ms, `inout` for large moves. No curve invented per component.
- Micro responses 120 to 180 ms; section entries 600 ms at most; nothing over 800 ms unless the card names a scene.
- Animate `transform`, `opacity` and color. Never `width`, `height`, `top`, `left` or `margin`.
- One entry choreography per screen: elements enter in order, 40 to 80 ms apart, eight items at most per group, once and not at every scroll pass.
- A state change is animated: open, close, success, error, an item appearing or leaving.
- `prefers-reduced-motion: reduce` removes movement, scale, parallax and autoplay; opacity and color stay.
- Libraries: CSS when it is enough; Motion (`motion/react`) in React; GSAP with ScrollTrigger in landings with narrative scroll; never a dependency the card does not allow. Three.js only if the product is the hero.

## States and assets
- Loading (a skeleton with the shape of the content), empty (it says why and offers the action), error (recoverable, it says what to do) and success (it confirms) are designed, never loose text.
- Real assets: product renders, drawn SVG, real data in the mocks. Never gray boxes, `lorem`, `placeholder` URLs or placeholder emojis.
- Specific copy: «Guardar cambios», not «Enviar».

## Anti-patterns
- Three identical cards in a row.
- A violet or blue gradient as the hero.
- The same fade-up on everything.
- An uppercase eyebrow over every section title.
- The same shadow on every card; `01/02/03` numbering with no real sequence.

## After: look before you finish
- For a `presentation` task, the capture loop of the builder (`rondas.md`) runs before saying done: capture, compare against `ref:`, correct.
- If two rules collide, clarity and accessibility win over aesthetics and motion.
