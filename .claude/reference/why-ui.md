# Why each rule of the ui module's steps is there

What was measured for `steps/m-ui.md` and `steps/m-ui-screen.md`. Read it when a rule looks like too
much.

**A presentation site verifies in proportion.** A presentation card spent nine of its ten hours on
mutation through the browser and on re-running timing scenarios.

**The main thread looks at the viewport, not the whole page.** A full-page capture weighed 10
thousand tokens, re-read on every request; one of the viewport, 1.5 thousand.

**`motion-audit` checks correctness, not life.** The screen the user called lifeless passed it with
three findings, because the few things it had responded well.

**The rubric is fixed before the first lap.** Going from 6 to 10 axes moved the score without the
product changing.

**The captures are looked at.** Over a screen with five real phone defects inside, the width check
caught 0, axe caught 0, a tagged scenario would have caught 0, and looking at the captures caught 5.
The label is whole in the DOM and truncated by CSS, so `toHaveText("FRÁVEGA")` is green while the
screen says `01 FR…`: it is not a weak test, it measures something other than what matters.

**The capture is not called `.spec.ts`.** In the repo this rule comes from, a capture filed as
`.spec.ts` contaminated the gate: what is not a test adds green cases that assert nothing and the
close's count lies.

**Two widths, always both.** A card that captured only at 390 px came out with an impeccable phone
and the board's fourth column cut off by the edge on desktop, with 1280 px of width available. The
agent looked at its captures, found real defects and fixed them —all of the single width the method
made it look at.

**One full pass and one that verifies the fixes.** Three laps over one screen.

**Against a production build.** The dev-tools indicator showed up in all twelve captures covering
different content, and took five of the reviewer's six findings. It was not that it was wrong —the
element does cover— it is that it does not ship.

**A reviewer first, then a person.** With the brief the reviewer takes out 3 of 5 defects without
dirtying the output. What the filter does not solve is *is it good?*: the typographic judgment and
the case of two nested interfaces where you have to know which one controls which got past it.

**`design-deslop` is not a design review.** It says so itself: *“it is not a full design review;
here you have a single job: that it stops looking generated”* and *“a cleanup that erases the intent
is worse than the slop”*.

**The most visible slop is in the data.** A screen with the design corrected and every validation
green was immediately read as *“excessively made with AI”*, and the cause was ten titles cycled with
`JOBS[i % JOBS.length]` over forty opportunities, distributed exactly 7/7/7/7 among the stages.

**The fields of a record are correlated.** Two runs of the same requirement: one chose the title of
the opportunity from a shuffled catalog and an accounting firm got “supply of plant uniforms”; the
other wrote the forty titles tied to its company's line of business —the freezing tunnel to the cold
storage plant, the light fixtures to the municipality— and scored one point more in the blind
evaluation than the one that won all the other dimensions. If the volume of activity does not know
what stage the deal is in, the screen shows noise shaped like data.

**Read what the declared material says.** Over four runs, two declared nothing, one declared
`ui-sans-serif, system-ui, …` —the default written by hand— and only one really chose. A `grep -c`
would have given green on the one that wrote the default.

**The pairwise judgment.** A card produced a more distinctive and worse screen, with all the reviews
green: different is not better, and none of the validations that run tells them apart.

**What year does it look like?** What is old makes you want to replace it. It is the easiest
question to answer of all in the step and the only one nobody asks: three intermediate screens
—linen, cream paper with serif, cardboard— passed all the reviews and would have failed it.
