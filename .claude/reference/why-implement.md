# Why each rule of steps 6 and 7 is there

What was measured for the rules of `steps/06-implement.md`. Read it when a rule looks like too much.

**The code is written in a single thread, and it is not the main one.** Writing code carries
implicit decisions, and two agents writing at once make decisions that collide (Cognition;
Anthropic: code has fewer parallelizable parts than research). Two thirds of a card's requests were
writing and verifying, made by the main thread with 90 to 200 thousand tokens of context re-read on
each one; in an `implementer` they start from the plan and the tests.

**One `implementer` per group of the file map.** A single implementer for the whole card made 130
requests with its context growing to 303 thousand tokens: $8.78 of $18.

**Verify while writing.** Correction was 34 % of the time in the measured runs; a wait with `sleep`
loops cost about 100 minutes of a card.

**Wait in the foreground.** A 7-hour run spent a good part waiting with ten-minute loops that asked
whether the subagent had committed.

**Delivered verified.** Half of the findings of the verdicts were live mutants or evidence not yet
written, and correcting them afterwards cost between 30 and 70 minutes; a second implementer round
to fix actions happened in 8 of 13 runs.

**Domain files marked `rule` start with their test.** The outer cycle is already test first and
mutation (T3) measures what TDD promises; an agent that writes the test after takes the expected
value from what the code returns.

**With nobody to turn the guard off, the gap is declared.** A bug fixed without a test and
declared is worth more than one fixed with a test nobody froze.

**No implementer or grunt runs a whole suite.** A `once.mjs` record is keyed to the exact code, so any later edit
invalidates it and `verify.mjs` repeats the run: the implementer's whole run saved nothing and cost one more suite per
group. The implementer runs what is bounded to what it touched; the first complete run is `verify.mjs` in step 8.

**A context cap on the implementer.** One reached 303 thousand tokens re-read on every request. `context-cap.mjs`
estimates the context from the usage of its own transcript and, past 300k, leaves it only the commit and the handoff, so
a fresh implementer continues with a clean context; an interface group of more than about 8 files is split by screen.

**The captures run with the card's filter.** A correction round that reruns the whole captures project rewrites the PNGs
of earlier cards, and the diff then carries evidence that is not this card's.
