# Why each rule of steps 0 to 4 is there

What was measured for the rules of `steps/00-resume.md`, `01-card.md`, `02-ambiguities.md`,
`04-scenarios.md` and `commands/scenarios.md`. Read it when a rule looks like too much.

## Resuming

**A quiet subagent is chased, not awaited.** An implementer hung for 127 minutes while the main
thread polled `git status`.

## Step 1

**What takes long starts in the background.** Scenarios in red together with their install were
11 % of a card's time, all in series.

**The `paths:` of `.claude/rules/`.** A rule that activates by path does not warn when it does
not activate.

## Steps 2 and 3

**A closed list answered in full.** In the method's first run, of four gaps three were resolved
without whoever decided perceiving them as a decision: *“I wrote it as obvious”*, *“I typed it
without pausing”*. An instruction to notice does not catch what does not present itself as a choice.

**`any-answer`.** Two runs of the same card asked themselves the same question —does it survive a
restart?—; one saved to a file, which works with both answers, and the other in memory. Ten blind
points of difference.

## Step 4 and `/scenarios`

**What can only be known by testing against the real world is tested before freezing.** A run froze
the tests with a file format, opened it afterwards in the real Excel, had to change it, and ended up
with two frozen tests in red that it could not touch.

**A title never starts with the number of an artifact.** It ages with it: in a real repo 72 % of
the titles started with a reference to a document nobody maintained anymore.

**The file goes by screen, not by card.** 58 files touched the same entity, and one tab had 12
tests spread over 5 files, each filed under its card; writing test 13 without knowing the previous
12 was the norm.

**A selector that names a business value is scoped to its container.** It was the second cause of
red in this method.

**No timing in a scenario.** A card put frame-time assertions in its scenarios; the suite failed
differently on every run, and nine of its ten hours were spent re-running it.

**Only the card's scenarios, never the whole suite, to see them red.** The whole suite took 7.8
minutes. A red test with a server left open hangs for minutes (72 s, and 125 + 64 + 68 + 42 s):
hence `--test-timeout` and `--test-force-exit` for that run only.

**A role and name possible by the specification.** Before implementing, a selector that finds
nothing and a feature that does not exist give the same error. Step 8 checks it with the code
there, but by then the test is frozen and fixing it costs a refreeze: here it is free.

**The reviewer reads the red.** A run froze a scenario where `await save(page)` returned the button
without clicking it; the test stayed red against a product that complied, and the card could not
close. Red run and reviewer go out together: one after the other they took 5.4 of a card's 27
minutes, with the main thread idle.

**One round, counted apart.** Two rounds on the red used the card's cap and the verdict reviewer
that mvp asks for was refused.
