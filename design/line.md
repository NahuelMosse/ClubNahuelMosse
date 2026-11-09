# Project design line

The web surfaces of the project — the docs site (`docs-site/`) and the API reference it embeds — wear the
same look as the mobile app. The app's values live in `apps/mobile/lib/theme/tokens.dart`; the web ones are
declared once in `design/tokens.css`, and every web screen uses them with `var(--…)`. A value that changes
in the app changes here too.

## 1. References

- **The app itself** (`apps/mobile/lib/theme/tokens.dart`): the palette — lime `#D4FF3D` on neutral
  black `#0A0A0B`, surfaces `#141416` / `#1E1E21`, hairline borders `#2A2A2E` — and the Inter / JetBrains Mono
  pairing. The site must read as the same product.
- **Stripe Docs**: a reading column of comfortable width, code blocks that sit on a raised surface, the API
  reference beside the prose instead of in another product.
- **Linear Docs**: dark neutral surfaces with a single accent used only for links, focus and the current page.
- **Vercel Docs**: quiet navigation, one primary action per page, hover and focus that answer in under 150 ms.

## 2. Direction

The readers are the course's evaluators and the developers who pick the project up: they read for minutes,
jump between the architecture, the data model and the API, and come back later. The site has to feel like the
app's manual — the same black and lime, calm, dense enough to scan — and avoid anything that looks like a
landing page. The accent marks links, focus and the current page; nothing else competes with the text.

- **Invention 3**: Docusaurus' structure stays; the look follows the app.
- **Density 5**: reading pages with tables and diagrams, not a data tool.
- **Expression 3**: product register (`reference/modern-interface.md`); only feedback motion.

## 3. Tokens

`design/tokens.css` declares them; the docs site loads it before its own stylesheet.

- **Neutrals** (dark): `--neutral-0` `#0A0A0B` (base) · `--neutral-1` `#141416` (surface) · `--neutral-2`
  `#1E1E21` (raised) · `--neutral-3` `#2A2A2E` (border) · `--neutral-6` `#64646E` (control border) ·
  `--neutral-8` `#85858C` (muted text) · `--neutral-9` `#A1A1AA` (secondary text) · `--neutral-12` `#FFFFFF`.
  Light mode redefines the same semantic names over a white base.
- **Accent**: `--accent` `#D4FF3D` in dark mode; `#4D6600` (olive ink) in light mode, where lime on white
  fails contrast. `--accent-on` is the text over the accent.
- **Semantic**: `--surface`, `--surface-raised`, `--text`, `--text-soft`, `--text-muted`, `--border`,
  `--focus`, `--danger` (`#FF4D6A`), `--success`. Screens use only these. Allowed pairs and their contrast:
  `--text` on `--surface` 18.4:1 · `--text-soft` on `--surface` 7.2:1 · `--text-muted` on `--surface` 5.0:1 ·
  `--accent` on `--neutral-0` 17.1:1 · light `--accent` (`#4D6600`) on white 6.5:1 · `--focus` ring against
  either base ≥ 3:1.
- **Space**: 4 px unit, `--space-1` … `--space-8` (4, 8, 12, 16, 24, 32, 48, 64).
- **Radius**: `--radius-1` 6 px (controls), `--radius-2` 10 px (surfaces), nested = outer − padding.
- **Shadow**: `--shadow-1` hairline plus a low layered shadow for raised surfaces; nothing floats on these pages.
- **Motion**: durations `--duration-instant` 80 ms, `--duration-fast` 120 ms, `--duration-base` 180 ms,
  `--duration-slow` 260 ms; curves `--ease-out`, `--ease-in-out`, `--ease-spring`; by use:
  `--motion-button-press`, `--motion-hover`, `--motion-focus`, `--motion-content-enter`. Only `transform` and
  `opacity` move; never `transition: all`.

## 4. Typography

**Inter** for text, the app's family, so the manual and the app read alike; **JetBrains Mono** for code, the
app's mono. Both fall back to `system-ui` / `ui-monospace` when the font is not loaded. Sizes: 14 / 16 (body,
line height 1.6) / 20 / 24 / 32 px, tracking from 0 down to −0.02 em as size grows. Weights: 400 body, 600
headings and labels, 700 the page title. `tabular-nums` on every number in tables.

## 5. The system: primitives, components and patterns

The site has no React component catalog of its own: Docusaurus (Infima) draws the navigation, the sidebar and
the prose. What the project adds on top is composed from the hand-written set in `design/components/`
(copied from the kit's templates and adapted to these tokens): `btn` for the actions a page adds (opening the
API reference in a new tab), `surface` for the embedded reference, the `stack` / `inline` primitives for their
layout. A new piece enters the set, with its states, before a page uses it.

Patterns: a page waits for the API reference with the frame's own loading, not a spinner of ours; links are
the only navigation; there is nothing to confirm or undo on a reading site.

## 6. State changes of the screen

| Change | Trigger | Rules | Feedback | Repetition and modes | Kind | Token | Reduced |
|---|---|---|---|---|---|---|---|
| Hover or press an action | pointer over / down on a `btn` | none | background tint; press scales to 0.98 | instant on keyboard | productive | `--motion-hover`, `--motion-button-press` | colour only, no scale |
| Focus an action or link | Tab | none | 2 px `--focus` ring | always visible on keyboard | productive | `--motion-focus` | no transition |
| The page content arrives | navigation | the sidebar stays | the article fades and rises 4 px | once per navigation | productive | `--motion-content-enter` | fade only |
| Switch light / dark | the theme toggle | the API reference inverts with the site | instant | — | productive | — | — |
