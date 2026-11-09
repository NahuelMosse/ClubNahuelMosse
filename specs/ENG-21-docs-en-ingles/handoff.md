# Designer handoff · ENG-21

Done: `ref/` (Stripe docs, 1440 and 390, 10 frames each, sheets, motion.json), `rondas.md` (Direction, rounds 1 to 3, Log), `rondas/r1..r3` captured with `--brand design/line.md --kind product` (KIT_PLAYWRIGHT_ROOT=D:/Temp/pw-root-eng21, Playwright installed there). Dead clicks 5 to 0, pasted boxes 4 to 0, LCP eager. docs-site tests: 4 pass.

## Not covered (turn budget)

- Brand sheet: `design/DESIGN.md` written with a `colors:` block from `design/tokens.css` and added to T8's list in card.md. *Could not run*: the format was not checked against `design-round.mjs --brand design/DESIGN.md`, and the last round was not rerun against a fresh build (`npm run build`, serve on 8707, `design-round.mjs http://127.0.0.1:8707/ --gpu --out specs/ENG-21-docs-en-ingles/rondas/r3 --brand design/DESIGN.md --kind product`, KIT_PLAYWRIGHT_ROOT=D:/Temp/pw-root-eng21).
- axe `scrollable-region-focusable` at 1280 and 390: *could not run*. Likely the strip `.markdown p:has(> img[src*='/screenshots/'])` in custom.css (`overflow-x: auto`, no tabindex) and wide tables. Fix: drop `overflow-x: auto` from the strip (wrap to 2x2 on narrow widths) or add `tabindex="0"` plus an aria-label to the wrapper in copy-docs.mjs; then run the docs-site tests.

- Labeled hamburger at 390 (`bare hamburger`): needs a swizzle of the navbar toggle; *could not run*.
- `hamburger, expanded: yes` at 1024-1440, 2 tap targets of 34 px at 390, hover-only reveals and min/max media queries from Infima: *could not run*.
- Skip link CTA separation and `accent reserved` rows: *could not run*.
- The final attribute order of the eager images (`src` before `loading`) is in the build only after a rebuild; r3 captures were taken with the previous order (same output).
- Server on port 8707 may still be up: stop it by its PID.
