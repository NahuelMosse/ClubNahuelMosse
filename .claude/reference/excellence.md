# Excellence: the last 10 % of a screen

Fourteen rules measured on nine award-level sites. Each is a pattern with numbers, how to check it and the tool that measures it.
`node .claude/tools/design-round.mjs <url> --out <dir> --gpu` measures rules 1 to 5 and the load of rule 6 in one call; the rest are read from
the captures or from `motion-audit.mjs <url> --measure` (`report.json`). A rule that is out of range is a difference to correct, not a taste.

## Typography and surface

1. **Display 5x to 9x the body, line height 0.95 or less.** Seen 7 of 9 (the other two put the display in 3D); 4.8x is the floor of the products.
   Check: `fontSize` of the `h1` over the one of `body`, and `lineHeight / fontSize`. Tool: `design-round.mjs` (`display/body ratio`).
2. **Negative tracking: display -0.02 to -0.03 em, body -0.01 to -0.03 em.** All the product sites; editorial fonts are already tight.
   Check: `letterSpacing / fontSize`; `normal` is 0 and fails. Tool: `design-round.mjs`.
3. **Two or three families and at most 9 distinct sizes in the first viewport.** Seen 7 of 9; a screen with 16 sizes has no scale.
   Check: count of `Math.round(fontSize)` over the visible text nodes. Tool: `design-round.mjs` (`font sizes`).
4. **Fine grain or noise over the flat surface.** 4 of 9, and 4 of the 5 dark or scene sites. Opacity 4 to 8 %, animated at 12 fps or less.
   Check: a `grain` or `noise` class, `feTurbulence` or a `url(*noise*)`; a 100 % capture over a dark plane. Tool: `design-round.mjs` (`grain`).
5. **One dominant tone and one accent, no pure black or white backgrounds.** 6 of 9 (`#08090A`, `#05090B`, warm whites, display-p3).
   Check: computed `background-color` of `body` and of each section against `#000` and `#fff`. Tool: `page.evaluate` on the captures.

## Motion

6. **The load is a choreography of 2 to 3 waves 200 to 300 ms apart, 0.9 to 2 s from the first movement.** A fourth wave at 3.9 s arrives after the
   awarded sites are done. Check: `load` of `report.json` grouped by `startMs` every 100 ms. Tool: `motion-audit.mjs --measure`, summarized by `design-round.mjs`.
7. **The load curve is ease-out with no overshoot; the spring is kept for what is touched.** 4 of 4 measurable; the largest overshoot seen is 2.3 %.
   Check: `grammar.shapes` and `maxOvershoot`. Tool: `motion-audit.mjs --measure`.
8. **Stagger has two registers: 25 to 40 ms between letters, 200 to 250 ms between blocks.** 82 ms is in neither.
   Check: `grammar.staggerMs` and `roles.cards.stepMs`. Tool: `motion-audit.mjs --measure --click <cta>`.
9. **The press scales, in 100 ms.** Seen 2 of 2 products (`scaleX`, 100 to 184 ms). Check: `roles.cta.press`. Tool: `motion-audit.mjs --measure --click <cta>`.

## Content and character

10. **One live detail that is real data, not decoration**: a clock, the cursor coordinates, a typeset load counter. 3 of 9.
    Check: captures at 0 and 2000 ms; the text changes with no interaction. Tool: `design-round.mjs` captures.
11. **A custom cursor carries content (image, coordinates, text), never a bare ring and dot.** 3 of 9 carry content; 5 of 9 keep the native one.
    Check: fixed elements with `pointer-events: none` under 160 px. Tool: `page.evaluate`.
12. **Sound only behind an explicit gate or a toggle visible from the first frame.** 3 of 9, all with a scene.
    Check: no `AudioContext` created before a gesture. Tool: `page.evaluate` with an init script.
13. **An image is treated in the language of the brand, never pasted raw**: duotone, grading, tone pulled to the background, fog of the scene color.
    3 of 4 of the sites with strong imagery. Check: a capture of one section with an image. Tool: `design-round.mjs` captures.
14. **A headline with two voices in the same sentence** (weight, style or tone): serif light with grotesk black, white then gray, handwritten notes.
    3 of 9. Check: the hero capture. Tool: `design-round.mjs` captures.

## Real assets, not code

An object or a place that exists is shown with a real photo treated (grading, duotone) or with video, never with 3D modeled by code: it looks cheap.
Generative work (SVG, canvas, shader) is for data, curves and textures. Sources with a free license: Pexels, Unsplash, Poly Haven, ambientCG, Fontshare.
Every asset is credited in `specs/<card>/CREDITS.md` with URL, author and license. GSAP has its own free license; it is not MIT.

## Measured on

| Site | Genre |
|---|---|
| emotion-agency.com | agency, preloader with counter and audio gate |
| signal-a.studio | typographic, no WebGL |
| overworldaudio.com | audio studio, WebGL scene |
| tympanus.net/Development/ScrollPanels | editorial, image panels on scroll |
| tympanus.net/Development/ScrollTextMotion | text motion on scroll |
| guillaumecolombel.fr | GSAP showcase, fogged 3D |
| illoca.unseen.co | GSAP showcase, duotone illustration and grain |
| linear.app | product, UI typography and micro-interaction |
| family.co | product, stagger and UI animation |
