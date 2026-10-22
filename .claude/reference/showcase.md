# Showcase: a screen that impresses on its own, in a video

Read it when the design line's **expression** dial is 8 to 10: a presentation, a landing, a demo,
anything that is shown rather than used eight hours a day. The product register —2 to 4— is in
`modern-interface.md`. Every item below names the component of `components.md` it comes from: a
showcase is **composed from the catalog**, not drawn.

*Measured: a presentation site built with the product register and a hand-written set scored 5 out
of 10 against the team's references —flat background, hover without depth, a figure that does not
lead—, after ten hours.*

## The message comes before the scene

A showcase sells something to someone. Before the first component, the design line writes three
lines: **who watches** —and what they do not know—, **what they must conclude** in one sentence, and
**the three proofs** that carry it. Every section is one of those proofs or it goes.

*Measured: a presentation of the method, with its design approved, still failed as marketing —
figures without saying what they compared, and whole sections that argued against the method—.*

- **Every number carries its context in the same frame**: what is measured, against what, and why
  it matters to the viewer. `97 %` alone says nothing; `97 % of 120 criteria met — without the
  method, 61 %` says it. Internal names —card IDs, criterion codes, tool names— are translated to
  what they mean to the viewer or removed.
- **A comparison leads with the difference that favors the thesis**, and the figure that costs is
  shown as the price of that difference, next to it: `20 min instead of 3 — and zero data lost`.
  Never a section whose conclusion is the opposite of the thesis.
- **Limits are told, not hidden**, in one sentence where the claim is made —`three cards measured,
  same model`—; not a section of their own that undoes what came before. Nothing is invented or
  stretched to fit the thesis: a claim the data does not hold is cut, not softened.
- **One idea per scene, said in the headline**; the panel proves it. A headline that describes
  (“Time”) instead of stating (“Twenty minutes buy a card nobody has to fix”) is a gap.

## What the video has to show, second by second

| When | What | From |
|---|---|---|
| **0–3 s** | Something alive in the first frame: a background with light or a grid that breathes, and a headline that enters by word with blur | `@magicui/light-rays` or `@aceternity/spotlight-new` or `@magicui/flickering-grid` + `@magicui/text-animate` (`by="word"`, `animation="blurInUp"`) |
| **3–8 s** | The main figure assembles itself and leads the screen | `@magicui/number-ticker` at the display size, with `@magicui/aurora-text` or a gradient on the unit |
| **scroll** | The content enters with blur, staggered, once | `@magicui/blur-fade` (0.4 s, 6 px, `blur 6px`, +0.04 s per item) |
| **scroll** | The story advances while something stays: a fixed panel, a beam that follows | `@aceternity/sticky-scroll-reveal`, `@aceternity/tracing-beam`, `@aceternity/container-scroll-animation` |
| **pointer** | Light follows the cursor on every surface | `@magicui/magic-card` (spring 250 / 30 / 0.6) or `@aceternity/card-spotlight` |
| **pointer** | The important card has a living border | `@magicui/border-beam` (6 s) or `@magicui/shine-border` (14 s) |
| **depth** | Glass and light edges, not flat boxes | `@kokonutui/liquid-glass-card`, inner highlight shadows |
| **navigation** | Switching section or tab slides, it never cuts | `@animate-ui/components-animate-tabs`, Motion Primitives `transition-panel`, `@magicui/dock` |
| **detail** | A card opens into its detail without leaving the place | Motion Primitives `morphing-dialog` |
| **the end** | A call to action that shines | `@magicui/shimmer-button` or `@aceternity/hover-border-gradient` |

## Every scene is composed, not a card on a void

*Measured: a first showcase built from the catalog scored 7 in impact and 4 in closeness to the
references; the judge's five gaps were all composition, not components —no charts, one card on an
empty background, flat cards, a diffuse glow, tiny text—.* So every scene follows these:

1. **A bento, not a card.** Each scene fills about 70 % of the frame with a grid of panels of
   different sizes —a large figure, a chart, chips, a short list—, like the references' dashboards.
   A lone card on an empty background is the failure. `@magicui/bento-grid`,
   `@aceternity/bento-grid`.
2. **Every number that can be a chart, is a chart.** Comparisons are bars that grow; evolutions are
   areas that draw; the active point glows and its value is read in the header of the card; the scale is visible.
   `@shadcn/chart` (Recharts area and bar) with the active dot in the accent and a soft glow
   (`filter: drop-shadow(0 0 8px <accent>)`); `@magicui/animated-circular-progress-bar` for a ratio.
3. **Surfaces with material**: an inner gradient (from the surface to a little of the accent), a
   1 px top highlight (`inset 0 1px 0 rgb(255 255 255 / .08)`), backdrop blur where something passes
   behind, and stacked cards where there is a collection (`@aceternity/card-stack`,
   `@kokonutui/card-stack`). Flat black with a hairline is the product register, not this one.
4. **One hero object**: something that is not text or a card in the first screen —an orbit of
   icons, a globe, a 3D marquee of captures, a map— (`@magicui/orbiting-circles`, `@magicui/globe`,
   `@magicui/icon-cloud`, `@aceternity/3d-marquee`, `@aceternity/world-map`).
5. **One accent per scene, with intention**: the accent lights one thing —the active bar, the main
   button, the chart's point— and ignites when the scene enters; never a diffuse stain behind the
   text.
6. **No dead frame**: while scrolling something is always moving —a pinned scene that advances, a
   figure that counts, a chart that draws, a slow parallax—. A frame of the showreel with nothing in
   motion and nothing lit is a gap.
7. **Readable in the video**: body text 16 px or more, labels 13 px or more, both at 4.5:1; one focus
   per scene, the rest recedes.
8. **Surface contrast, not one dark plane**: at least one card filled with the accent's gradient and
   light text, and one light panel in the dark page —the references do it—; a page that is all dark
   cards with a thin accent border reads as “a well-built dashboard, not a showreel”.
9. **The hero object is the protagonist**: 50–60 % of the first screen's height, with material
   —glass that refracts, a glowing sphere or ring, a 3D object— and parallax with the pointer; small
   icons around a number do not count.
10. **Charts with craft, never the library default**: an area with a gradient fill fading to the
    background and a glowing active point that follows the pointer while the header of the card reads its value; bars that
    grow staggered with the key one in a second accent. Flat single-color blocks are the default.
11. **Every section fills the viewport when it is the focus** —pin it, or size it to the screen—: no
    300 px of black between sections, no third of the frame empty.
12. **Nothing broken in a frame**: no clipped glyph (a `%` cut by `overflow`), no nested scroll inside
    a card, no box with two lines and empty space. The judge looks at frames; so does the client.

*Measured: the second lap, with rules 1–7 applied, still scored 5–6 —“correct but predictable,
amber bars on black, no memorable moment”—; rules 8–12 are the judge's five gaps.*

## The direction that goes with it

- **A deep background and one accent that glows** —like the team's references: near-black with a
  warm or electric accent, or a bright neutral with a vivid one—. The accent appears in light, not
  only in fills: beams, glows, the spotlight.
- **Display type with character**, large and tight (-0.02 to -0.04 em), with a calm text face; the
  figure in tabular numbers at display size.
- **Layers**: background (light, grid, noise) → glass surfaces with light edges → content → the
  pointer's light on top.
- **Choreography, not decoration**: one main movement per section; the rest settles. What moves
  helps read: the figure that assembles, the panel that stays while the story advances.

## The system behind, for what the catalog does not cover

GSAP with ScrollTrigger for scroll timelines —`scrub: 1` or more, never `0`—, Lenis for smooth
scrolling synced to ScrollTrigger (`lenis.on('scroll', ScrollTrigger.update)`), and a shader or
Three.js only if the direction asks for it. The vendored skills `build-awwwards-quality-sites` and
`cinematic-gsap-lenis-motion-system` (Meng To, MIT) carry the recipes.

## What is touched is tested by touching it

A frame does not show how a drag feels. Every signature interaction —drag a globe, tilt a card,
open a dialog, switch a tab— is **exercised** in step 9 with a script: drag a known distance, hover,
click, and compare what moved against the rule.

- **Direct manipulation is 1:1**: the point under the pointer stays under the pointer. A globe of
  radius `r` px rotates `dx / r` radians for `dx` px of drag; a slider moves its thumb the same
  pixels as the pointer. A library default that turns a 100 px drag into half a turn is a defect.
- **Inertia, if any, decays in under 1 s** and never reverses; with reduced motion, none.
- **Pointer effects follow without lag or overshoot**: the spotlight under the cursor, the tilt at
  most 8–10°.

*Measured: a globe from the catalog passed the judge's frames and the motion audit; the user dragged
it once and it spun far more than the hand.*

## What does not change in a showcase

- Only `transform`, `opacity` and `filter` animate; never layout properties.
- **Reduced motion**: backgrounds still, text without the staggered entrance, figures at their
  value, no parallax; the content and the light on hover stay.
- **Slow hardware**: `motion-audit --cpu 4` with no long frames while scrolling; heavy backgrounds
  lower their density or stop off screen.
- Content readable from the first frame and every control reachable by keyboard.

## How it is judged

`showreel.mjs` records the 30–45 s tour above; a blind judge scores it against the design line's
references —impact in 3 s, choreography, depth and materials, detail, *would you show it in a
video?*— and it passes at 8 or more (lens `visual` of the `judge`).
