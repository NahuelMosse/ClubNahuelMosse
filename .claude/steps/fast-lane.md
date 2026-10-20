# The fast lane

A card that only changes a text, a layout, a style or an asset does not need the full method. The plan says
`lane: fast`, the main thread edits, and hooks that fail closed keep the card honest: when the diff leaves the
conditions, the lane is over and the card goes through the normal plan. The lane is presentation only,
so it needs the module `ui`: with `ui` off in `node .claude/tools/kit.mjs status`, `require-bar.mjs` blocks it.

## Conditions, all of them

1. **Kind of change:** `text` (labels, messages, help), `layout` (move, reorder, align a visual element),
   `style` (spacing, size or color within the tokens) or `asset` (replace an icon or an image).
2. **Presentation files only:** markup, CSS, components without logic, i18n text files. No domain,
   application, API, database, migrations, configuration, dependencies, auth or permissions.
3. **No change of behavior:** no state, conditions, data bindings, routes or handlers added.
4. **At most 30 changed lines and 3 production files**, counted from the start of the card.
5. **The card asks for it without ambiguity:** an `AMB-NN` (from 01 on) takes it out of the lane.
6. **No text with business weight:** prices, amounts, legal or terms text, error messages that explain a
   rule, emails to the customer.
7. **No existing test changes**, with one exception: replacing a string literal a test asserts, when the
   card's change is exactly that text. The old literal is one the card took out of the presentation files and
   the new one is one it added. In a translated text, the text changes in every locale or it is not this lane.

## What is skipped and what is kept

**Skipped:** the delegation to the `implementer` (the main thread edits), the planner and the long plan,
mutation, the new tests in red (replaced by visual evidence), and in step 8 the inspector, the reviewer, the
pairwise judge and `screen-audit.md`.

**Kept:** the requirement read and frozen (step 1, invariant 1) and the ten questions, one line each; the
existing suite green; captures before and after at the app's widths, in light and dark; axe and contrast over
what was touched; no text overflow at the real length and with pseudo-localization; the PR and the closing
comment only from the validations, published as in `/close`.

## The plan of the lane

`specs/<card>/plan.md` has only these sections:

- `## Lane`: `lane: fast · <text|layout|style|asset> · <why it fits>`.
- `## File map`: at most 3 production files, each line with `presentation`; plus the tests whose literal
  changes, each with `literal: "<old>" → "<new>"`.
- `## Time plan` with `cap: <N> min`.
- `## Verification`: `suite:`, `captures:`, `a11y:`, `overflow:`.
- `## Changes to existing behavior`: README and ASVS with their `unchanged` line, and the text or style that
  changes; `- Dark mode: none` if the app has no dark theme.

## Order

`/card` → the ten questions → capture `before-<width>-<theme>.png` in `specs/<card>/` → the short plan →
the edit → `node .claude/tools/verify.mjs` (in the background with a log; no `sleep` or `until grep …` loop) → capture `after-<width>-<theme>.png` → `/close`. Widths are 1280
and 390 unless the app has others.

## Who stops it

`node .claude/tools/lane.mjs` lists what falls outside the lane and exits 1. `require-bar.mjs` blocks the
write that would leave it, `guard.mjs` a test edit beyond the literal, `guard-shell.mjs` any write by shell
to a test or production file. Leaving is at any moment and final: remove `lane: fast`, write the full plan
(`.claude/steps/05-plan.md`), and the code goes through the `implementer`. A replaced literal of a committed
test needs the event `<ID>-TESTS · <date> · literal updated · <file> · "<old>" → "<new>"` in
`ambiguities.md`; `required.mjs` asks for it, for the captures, `accessibility.md`, the output of
`node .claude/tools/overflow.mjs` (module ui) and a line in `specs/lane.md`.
