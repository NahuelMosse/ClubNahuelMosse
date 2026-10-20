# Module ui · Step 9, looking at the screen

Read only if the diff touches a screen, while `ui` is on in `.claude/kit.json`. The rest of the
module is in `steps/m-ui.md`. Why each rule is there: `.claude/reference/why-ui.md`.

## At a glance

Step 9, when the diff touches a screen: a `captures.capture.ts` file (own Playwright project, not `.spec.ts`) has one
`test('@capture <view>')` per view that navigates and does `page.screenshot()`; run it with the card's filter
(`npx playwright test --project=captures --grep "@capture <view>"`) against a production build, at 1280×900 and 390×844 (at `poc`
only the width the card names, or 390). Also `motion-audit.mjs <url> --only <selectors the card added>` (a line of `## Verification`;
`--cpu 4`), the contact sheets of new state changes, and a blind pairwise comparison against the previous screen in both orders
(a loss is an action) by a `PAIRWISE` `reviewer` over pairs you capture with `app.mjs probe`. The visual judges are `reviewer`s whose prompt starts with `VISUAL-JUDGE` and open with `help.mjs judge` and `judge-context.mjs visual`: with 12 or fewer production files, a single one does every job; their first lap goes in the step 8 message, the second only when an `ACT` closes with no
command or the map has 15 or more production files. The brief, not a list of defects, is what they look against; the verdict says
a model gave it. **The card outranks motion:** what the card says disappears or is replaced leaves the DOM in the event's task, so the
judge raises no `ACT` against it and item 7 of the audit is `not applicable · the card pins it`. A screen audit
(`specs/<card>/screen-audit.md`) has no blank row. No strip, or no server: `could not run`.

**Closes with:** the strips at both widths exist, with who looked at them, and no visual action is open.

Read the rest only when the card creates a screen or a component (`steps/m-ui-craft.md`), the design line's expression is 8 or more (`steps/m-ui-showcase.md`), or a verdict contradicts the pairwise result.

## The verdict

**What the verdict looks at is light.** The strips at both widths are looked at first by a
`reviewer` with the plan's `## Visual brief`; whoever runs step 9 then looks at what it flagged and at
the states the card changed, in captures of the viewport —not the whole page— at scale 1. The
verdict is still theirs.

**When it runs.** The first lap of the visual judges goes out **in the same message as the step 8
inspector and verdict `reviewer`** (`steps/08-verify.md`), not after their round: every action goes into one
`actions.md`, one combined `implementer` round fixes it. The second lap runs after that round and **before**
the final `verify.mjs`, only if some `ACT` closes with something that is not a command or the File map names
15 or more production files; otherwise the command of each `ACT` and the final `verify.mjs` verify the fixes. **The second lap
never resumes a judge with `SendMessage`** (that rewrites its cache): it is a new `VISUAL-JUDGE` launch whose prompt is `CONFIRM`
and only the `ACT` lines. A visual `L` `ACT` closes with a measurement (`motion-audit`, `overflow`, a `count()`), not a look.

**Who runs what.** Every judge with vision of this step —strip, reference comparisons,
`review-animations`, showcase judge, message reader, `/design-deslop`— is a `reviewer` whose prompt starts
with `VISUAL-JUDGE`, except the pairwise one (`PAIRWISE`). The mechanical audits (`motion-audit`, axe, `overflow`) are commands: a line of
`## Verification`, or an `executor`; the accessibility judgment is the step 8 `inspector`'s. Never
`general-purpose` (Opus and the whole context): `review-cap.mjs` blocks it during a card.

**The motion is looked at, not only the pixels.**

- **Always, mechanical** —not at `poc`: `skipped: not required by grade poc`—:
  `node .claude/tools/motion-audit.mjs <url> --only <selectors>`, on what the card added or changed. It reports:
  - every element that does not respond to hover, press or focus;
  - every state change that teleports;
  - durations out of range, `ease-in` to enter, `transition: all`, animated layout;
  - long frames, also with `--cpu 4`;
  - what remains with reduced motion.

  When the card changes the component set, it runs on its gallery instead. It is one line of
  `## Verification`, and runs in parallel with the rest. **It checks correctness, not life**: how
  much responds, with what depth, and whether it feels like the references, is judged by the
  comparison below and by the person.
- **Always, to look at:** the contact sheets of the signature interactions and of the new state
  changes (`--frames <selector>`), next to the captures.
- **Always, when the card touches UI**, a **blind pairwise comparison against the previous
  screen** —or a screen of the same product that already worked—, by the `PAIRWISE` reviewer, blind, on strips from `app.mjs probe`. See “did it come out better?” below.
- **If the card creates a screen**, the judges and the reader protocol of `steps/m-ui-craft.md`, “A new screen”.
- **The screen audit of the design line** (section 6b): each item with its evidence
  —the `motion-audit` report, a frame of the showreel, a scenario— or `not applicable` with the
  reason. It goes in `specs/<card>/screen-audit.md`. A blank row stops the close. **At `poc` there is
  no design line and no audit file**: the verdict is against the brief.
- **If the design line's expression is 8 or more —a showcase—, it is judged in video:** read
  `steps/m-ui-showcase.md` before judging; not read under 8.
- **The person gives the last verdict moving it live**, with the URL running: *does it respond to
  what I do?*

A tagged test asserts on the DOM and the user reads pixels: a label truncated by CSS passes
`toHaveText` while the screen says `01 FR…`. The captures are looked at.

→ **Produce the artifact** — this one is mechanical and binary:
```
npx playwright test --project=captures
```
It is a file of the repo's own: one `test('@capture <view>')` per view, which navigates and does
`page.screenshot()`, and asserts nothing. Whoever implements **does** touch it: it is not tagged by card.

**It runs with the card's filter** (`--grep "@capture <view>"` or its own capture file) in every correction
round: no run rewrites the PNGs of another card, and `required.mjs` reports a PNG of another card in the diff.

**And it is not called `.spec.ts`.** It goes as `captures.capture.ts`, in its own Playwright
*project*, outside the one the gate runs: what is not a test does not carry a test's name.

→ **Two widths, always both** —at `poc`, the grade leaves out the desktop one: only the width the card
names (320, say), or 390 px when it names none (the `capture-widths` line of the bar)—:
```
{ width: 1280, height: 900 }   // desktop — where the work is done
{ width:  390, height: 844 }   // phone   — where it breaks
```
What is looked at gets optimized and what is not gets broken.

**The visual judge has a cap of its own: one full pass, and one more that verifies the fixes of the first when the second lap is due** (“When it runs”) —the comparison against the references and the showcase judge count together; `review-cap.mjs` does not count the `VISUAL-JUDGE` calls, so the number is held here; `PAIRWISE` has its own two—. **With 12 or fewer production files in the File map (`bar.mjs --route`) a single `VISUAL-JUDGE` goes**, doing the strip against the brief and, on a new screen, the references and the animations in one pass; from 13, one judge per job. Every view, at every width and in the states the card changed, is captured and judged once. After a fix only the viewport and state it affects are recaptured and looked at again; a fix to a rule that holds at every width recaptures every width of that view.

**The first card that touches a screen creates it**, and each card that adds a view adds its
`@capture`: if nobody is assigned to write it, step 9 never runs and is decorative.

**Against a production build, never the dev server:** its dev-tools indicator is not what ships.

Either the strip exists or it does not. If the server does not start, it is **could not run** and
does not close.

→ **Desktop, composition, data and material.** If the card creates a screen or a component, or seeds
data, read `steps/m-ui-craft.md` with the captures in view (desktop, `/design-deslop`, seeded data, material); not for a change to an existing screen.

→ **The verdict is given by someone looking, with the plan's `## Visual brief` alongside.** First a
`reviewer`; then a person over what remained.

**The brief, not a list of defects.** The brief says what the user has to be able to do and read; a
list of defects is the answer and invalidates the measurement. A brief line that contradicts the snapshot (an exit
animation on what the card says disappears) is a `fails` of the plan against the snapshot, not a defect of the screen.

This filter solves *is it obstructed or illegible?* —verifiable against something written—. It
**does not** solve *is it good?*: the typographic judgment and two nested interfaces, where you have to
know which controls which, stay for the person who reviews the PR, and the PR says the verdict was a model's.

→ **The question that no skill answers: did it come out better?**

The judges measure against a bar, none against the previous version, and the verdict compares
against the brief, the document that chose the direction. **If the direction was wrong, the step validates itself.**

The counterweight is a **pairwise blind judgment, whenever the card touches UI**, not only when it
creates a screen: the `PAIRWISE` reviewer gets the strip of the previous screen —or a screen of the
same product that already worked— and the new one, without knowing which is which, and answers
which is better on a **fixed rubric**: hierarchy · control design and affordance · states ·
consistency · mobile · “this year's professional software”.

- It runs **in both orders**, A/B and B/A: the verdict of a dimension stands only if both orders
  give the same winner. **A tie, or two orders that disagree, count as no verdict**.
- **A loss of the new screen against the previous one is an action**, with the dimensions it lost
  and what the winner does that this one does not.
- If there is no previous screen nor one of the same product that worked, it is `not applicable`
  with that reason.

→ **And the question that comes before all: what year does it look like?**

With the strip in view, without looking at the code: **does this look like software delivered this
year, or like ten years ago?** If “ten years ago”, it does not matter that the rest is fine: a tool
that looks old the day it is delivered was born with an expiry date.

**And live, not in the capture: does it respond to what I do?** Move the mouse, tap, switch views,
scroll. A capture does not show motion; a screen that reacts to nothing feels old even if it looks good.

→ The strip is attached to the closing comment, together with who looked at it.
