# ENG-21 · rondas del sitio de documentación

## Direction

Concept: the app's manual — the same black and lime, calm and dense enough to scan, in the structure of a first-class developer docs site.

**Surface:** a technical manual page. Components that express it: (1) the sidebar with a hairline edge and an accent bar on the current page; (2) code blocks on the raised surface with a hairline border; (3) the home page's four captures as one framed strip with hairlines between them.

Brand sheet: `design/line.md` + `design/tokens.css` (the app's design line; no new palette or type). Families: Inter (text), JetBrains Mono (code). Palette: lime `--accent` on neutral black in dark mode, olive ink `#4D6600` (OKLCH L 0.47) in light mode; text on surface 18.4:1, muted 5.0:1 (`design/line.md`). `palette: text contrast (WCAG AA): 0` pairs under 4.5:1 in every round. Departure from the genre cliché (white page, indigo links, purple gradients): black and lime with olive ink in light mode; the accent only marks links, focus and the current page.

References (captured in `ref/`, `devdocs-stripe-*`, 1440 and 390, 10 frames each, inner page /get-started): Stripe Docs gives structure (sidebar, reading column, code on raised surface, hairline sections). Lateral: Linear Docs and Vercel Docs, from `design/line.md` (single accent; hover and focus under 150 ms), not captured, cited as principles only.

| Trait | Reference | Measured on this screen |
|---|---|---|
| Reading column and hierarchy (32 / 24 / 20 over 16 px, tracking −0.02 em) | Stripe /get-started h1 32 px 700, sections split by hairlines | h1 32 px 700; h2 24 px with a 1 px top border; prose `max-width: 72ch` |
| Quiet navigation (hairline edges, accent bar on the current page) | Stripe sidebar | 1 px border under the bar and beside the sidebar; 2 px accent bar on the active link |
| Feedback motion (hover, press, focus, entry) | Vercel Docs, `design/line.md` | `--motion-hover` 120 ms, focus 80 ms, entry 260 ms, only transform and opacity |

Motion grammar: Stripe's own motion measured in `ref/motion.json`; this site keeps to the line: 120 ms ease for hover, 80 ms press and focus, 260 ms `--ease-out` for the content, one rise of 4 px, nothing staggered, nothing follows the cursor; reduced motion: fade only.

Three layout decisions that differ from Stripe: no top product tabs (a single sidebar holds every section); the title of the home page is the README's centered logo and title, not a left h1 with a subtitle; the four app captures are a framed strip, not a card grid.

## Round 1 (baseline at 390, 768, 1024, 1280, 1440, `rondas/r1`)

1. Character: the page title drew twice on the home (frontmatter h1 over the README's own); `hide_title` on the home page. The skip link was a grey chip, now the accent fill.
2. Hierarchy and typography: Infima's 3 rem h1 against Stripe's 32 px; the line's scale (32 / 24 / 20) and 72ch prose measure.
3. Depth and color: nav shadow and cards replaced by hairlines (`--border`), code blocks bordered, table heads muted; the active sidebar link gets a 2 px accent bar.
4. Composition: measured fails: 5 sidebar sections with `href="#"` (dead clicks), 4 pasted boxes (screenshots as loose images on the page), LCP image lazy. Sections get a generated index page; the captures become one framed strip; the images load eager.
5. Motion and states: TOC links 21 px high at 1280+, 44 px touch targets at 390 (toggle, brand, search, breadcrumbs, TOC button), copy button always visible, press 0.98 on `.btn`.

- Visual judgment against `ref/devdocs-stripe-1440-10.png`: our page lacked the sectioning and the weight of the title; Stripe's sidebar is denser (14 px, hairline).
- product rows r1 vs Stripe: content span 122% (range 85%+); rows in first viewport: 7 sidebar links vs 12 for Stripe; sidebar link height 40 px vs 32 px for Stripe.

## Round 2 (`rondas/r2`)

1. Character: dead clicks 5 → 0, pasted boxes 4 → 0 (r1 → r2). The strip holds.
2. Hierarchy and typography: sidebar link 14 px with `--space-2` vertical padding (40 → 36 px rows, Stripe 32 px).
3. Depth and color: the skip link still painted `#f6f6f7`: the theme's rule won on order; selector `a[class*='skipToContent']` raises the specificity.
4. Composition: the LCP image still read as hidden at t0 at 1440 because the entry animation started from opacity 0; it starts from 0.2.
5. Motion and states: `compare` of the measured entry (260 ms, `--ease-out`, one wave) against Stripe's measured transitions in `ref/motion.json`: Stripe has no entry on page load; ours is one 260 ms rise, kept by the card (behavior: view).

## Round 3 (`rondas/r3`, the last)

1. Character: LCP image eager and visible at t0 at every width; dead clicks 0 at 390 and from 1200; broken images 0, alt painted as text 0.
2. Hierarchy and typography: h1 32 px 700 with −0.02 em; display/body ratio reported 2-3 (info).
3. Depth and color: AA text contrast at 0 failing pairs at every width; the skip link in light mode is olive ink on white (6.5:1), which the CTA-separation row reads against the olive link ink (0, a hidden control only visible on focus).
4. Composition: 1440 home reads as the logo, the title and one strip of four captures, next to the sidebar; mobile keeps the strip scrollable.
5. Motion and states: reduced motion cancels the 0.98 press and the rise.

Open (not chased, owned by the theme or Infima, not by this card's CSS): `hamburger, expanded: yes` at 1024-1440 (Infima's toggle element), `bare hamburger` at 390 (the label «Menu» is drawn with `::after`, the check reads text content; a swizzle of the toggle would fix it), 2 tap targets of 34 px at 390 (theme buttons), 5 hover-only reveals and desktop-first media queries (min 4 / max 18) in Infima's own stylesheets, `accent reserved: 15-17` (links colored with the accent), and the skip link CTA separation.

## Log

- L1 · round 1 · double home title, 5 dead sidebar links, 4 pasted screenshots, lazy LCP, touch targets
- L2 · round 2 · skip link specificity, sidebar density, LCP at t0
- L3 · round 3 · captures and numbers of the last round; open rows listed above
- L4 · OUT · a labeled hamburger needs a swizzle of the navbar toggle, outside T1/T8/T9
