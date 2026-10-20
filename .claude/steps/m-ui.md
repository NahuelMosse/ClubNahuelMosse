# Module ui · what it adds to the steps

Read the section of the step you are on, only while `ui` is on in `.claude/kit.json`. What it adds:
the visual brief in the plan (step 5), the accessibility pause (step 8), the look at the screen
(step 9, in its own file) and the captures in the close. **Designing or implementing a screen:**
`.claude/reference/components.md` —installed, never drawn— and `modern-interface.md`, or
`showcase.md` if it has to impress. A repo without `ui` has no screens: the criteria I1 to I25,
T12, T14, O11, O15, S4, D13 and V5 are answered in the bar by the line `ui · off by decision · <reason>`.

## At a glance

With a screen: step 5 adds `## Visual brief` to the plan (components of the set the screen is composed of, the state-change rows
the card adds, signature interactions for a new screen, one line per view on what it does with the extra desktop width); the
design line `design/line.md` and the component set `design/components/` are created by the first card that needs them (at `poc` neither;
at `mvp` the line and only the components the card uses). Step 8 adds the accessibility pause. Step 9 and check 17 of `/close` are
`steps/m-ui-screen.md`, read only if the diff touches a screen. A presentation site (no stored data, no routes that write, no users) verifies
in proportion: data, security and operation are `not applicable` with that reason.

The font is decided in step 5, not in step 9: Inter, installed from `.claude/templates/components/fonts` (`InterVariable.woff2`), never
`system-ui`. `verify.mjs` flags on `design/`, for a card that touches a screen:
- `I-line`: no `design/line.md`.
- `I-tokens`: a color, duration, space, radius or shadow written by hand instead of `var(--…)` (declared once in `design/tokens.css`).
- `I-components`: a control written by hand instead of taken from `design/components/` (or the catalog).
- `I-states`: controls without `:hover`, `:focus-visible`, `:active` and `:disabled`.
- `I-motion`: a new screen with no `transition`/`animation`, or motion with no `prefers-reduced-motion` rule.

**The main thread writes the visual brief in 10 lines or fewer, in the plan.** It does not read `templates/design-line.md`, `rules/interface.md`
nor the component set to write it: the `implementer` reads them (`steps/06-implement.md`) and turns the brief into the design line and the screen.

Read the rest only when the plan's visual brief has to be written for the first time in the repo, or the component set has to be created.

## Step 5 · The visual brief

`## Visual brief` — **only if the card touches a screen**, **10 lines or fewer, written by the main thread without reading the
design templates**: `.claude/rules/interface.md` (which loads by itself on touching a screen file) and `.claude/templates/design-line.md`
are the `implementer`'s. It starts from
the project's design line (`design/line.md`; if it does not exist, this card creates it —the `implementer`, with
`.claude/templates/design-line.md`— together with the component set from
`.claude/templates/components/`, which the main thread copies to `design/` before launching it, `steps/06-implement.md`; **by grade** `node .claude/tools/bar.mjs` says what is left out:
at `poc` no line and no set are made and the brief stands alone, at `mvp` the line is made and the
set holds only the components the card uses) and brings: which components of the set the screen is composed
of —and which enter the set first—, the rows of the screen's state changes that the card adds,
and its signature interactions if it creates a screen. The values, from
`.claude/reference/modern-interface.md`. **A presentation site —no stored data, no routes that write, no users— verifies in proportion**: the
bar answers data, security and operation as `not applicable` with that reason; the scenarios are
behavior only; speed is measured once by `motion-audit --cpu 4`.
**If the project has a design line but no component set
and the card adds controls or changes how the screen responds, the set is created in this card**
and goes in the file map: `verify.mjs` asks for it at step 8, and finding it out there costs a lap.
At `poc` neither is created; the plan's bar carries the `off by grade` lines for them.

## Step 8 · Accessibility, if the diff touches a screen

Pause 5 of `/validate`. What needs a screen reader stays `could not run` until step 9.

## Step 9 and the close · the screen

If the diff touches a screen: **read `.claude/steps/m-ui-screen.md` now.** It holds the captures at
1280 and 390 px against a production build, the motion audit, the blind comparisons, the data and
the material, and the verdict. Check 17 of `/close` is its strip of captures. If the diff does not
touch UI, it is not read, check 17 is skipped and that is said. Why each rule is there:
`.claude/reference/why-ui.md`.
