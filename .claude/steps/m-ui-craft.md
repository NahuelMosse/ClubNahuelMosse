# Module ui · Step 9, composition, data and material

Read only if the card creates a screen or a component, or seeds data, while `ui` is on in `.claude/kit.json`.
It is part of `steps/m-ui-screen.md`, which links here; the rest of the step is there.

## At a glance

A new screen gets the `VISUAL-JUDGE` reviewers (one with 12 or fewer production files; otherwise `review-animations` and a blind
comparison against the design line's references, each dimension under 7 an action), the 10-minute screen reader protocol of
`reference/accessibility.md` (I15) and the APG checklist per complex component (I16). Desktop is not the phone stretched: the
brief says in one line what each view does with the extra width, and two captures that differ only by scale are an action. With
the captures in view, `/design-deslop` runs in a subagent for a new screen or component. Seeded data is combined, never cycled:
`grep -rn "\[i % " <seed>` is empty, distributions are uneven, the fields of a record are correlated. The brief's five material
lines (typography, canvas, separation, radius, density) are read against what is on screen:
`grep -hoE "font-family: *[^;]+" <styles>` must show a decision, not `system-ui`.

Read the rest only when the card seeds data that has to look real, or `/design-deslop` flags a composition you must fix.

## A new screen

If the card creates a screen, two judges run in parallel subagents, each a `reviewer`
whose prompt starts with `VISUAL-JUDGE` —**with 12 or fewer production files in the File map (`bar.mjs --route`) a
single `VISUAL-JUDGE` does both jobs in one pass**; its first calls are `help.mjs judge` and `judge-context.mjs visual`, not reads one by one—:
- `review-animations`, with the sheets and the motion code;
- a **blind comparison against the references of the design line**: the captures and the sheets
  against the references, scored 1 to 10 on hierarchy, feedback, continuity, detail and “looks
  like this year”, without knowing which is which.

Under 7 in any dimension is an action, with what is missing.

**For a new screen the verdict includes** the 10-minute manual screen reader protocol of
`.claude/reference/accessibility.md`, recorded with reader, browser and result (I15), and the APG
checklist of each complex component (I16); a component chosen from the catalog is judged against its
sheet in `.claude/reference/ui-patterns.md` (I18–I25). What nobody ran stays `could not run`.

→ **Desktop is not the phone stretched.** It is built mobile-first because covering both is
cheaper, but **desktop is the main destination**: it is where the whole workday happens. With the
two strips side by side, the question is what the desktop does with the extra space.

| | Does not pass |
|---|---|
| Same layout at both widths, just bigger | a column that stretches, cards that grow and nothing else |
| The extra space all goes to margins | the content takes the same room and there is air left on the sides |
| A phone pattern served on desktop | a horizontal carousel where all the columns used to fit |

The desktop has to **show something that does not fit on the phone**: more columns at once, a table
instead of stacked cards, the detail next to the listing instead of on another screen. If the two
captures differ only by scale, the desktop is not designed.

**The `## Visual brief` says it beforehand:** one line on what each view does with the extra
width. If it is not written, it is decided by looking at the diff and the step confirms itself.

→ **With the captures in view, run `/design-deslop` —if the card created a screen or a component,
in a subagent so it does not take up the main thread—.** One more text or control on a screen that
already exists does not change its composition: the design line and the checks of `verify.mjs`
cover it. It is the other question of this step, and the brief does not answer it: not *is it
broken?* but *can you tell a model generated it?* —flat hierarchy, no focal point, twelve identical
cards, a smeared accent, structure made of borders instead of space—. It goes here and not in step
8: **slop is compositional and invisible in a diff.** Its first pass is to look at the render with
eyes squinted; the second, only then, the line. It brings its own section on what **not** to touch,
which is what keeps the correction from coming out worse than the defect.

**`design-deslop` is not a full design review**: it has a single job, that the screen stops looking
generated, and a cleanup that erases the intent is worse than the slop. **It does not choose a
direction nor repair it.** If the screen came out wrong because the direction was wrong, it will not
say so, and asking it to fix that is asking for what its own file declares out of scope.

→ **And the most visible slop is not in the CSS: it is in the data.** `design-deslop` looks at
composition. The first thing that gives away to a human eye is synthetic content, and nobody looks
at that.

| Signal | What shows on screen |
|---|---|
| `array[i % array.length]` | the same title four times, in the same order in each column |
| Perfectly even distribution | seven opportunities in each of the four stages |
| Round amounts or in progression | `$ 1,000,000`, `$ 2,000,000`, `$ 3,000,000` |
| A single axis of variation | all the names the same length, all the dates in the same month |

**Seeded data is combined, not cycled**, and the distributions come out uneven on purpose: one
stage with two and another with eleven is what really happens. If the card asked for them to “look
real”, that is a requirement and it is verified like any other — it is not seed decoration.

`grep -rn "\[i % " <seed>` is the cheapest check in this whole step.

**And the fields of a single record are correlated, not drawn separately.** Each field can be varied
and believable on its own and the whole record still be impossible: the title is tied to the
company's line of business, not chosen from a shuffled catalog. The same with time: an opportunity in
Negotiation carries more interactions than one in Prospect; the volume of activity knows what stage
the deal is in.

→ **And the material against what was declared.** The brief's five lines —typography, canvas,
separation, radius, density— are checked against what is seen. **The default does not fail for
being ugly, it fails for being recognizable**, and that is why no review flags it.

```
grep -hoE "font-family: *[^;]+" <styles>
```

**It is not enough that it is declared: you have to read what it says.** A `grep -c` gives green on
`ui-sans-serif, system-ui, …`, which is the default written by hand. **The question is not whether
there is a line, it is whether there is a decision.** It holds for the other four of the material
too: a declared `--radius: 12px` and a default 12 px radius look the same on screen. The brief says
what was chosen and why; step 9 looks at whether that is what is there.
