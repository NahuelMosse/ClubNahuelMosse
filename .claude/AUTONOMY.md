# Autonomous mode: the card runs with nobody in the loop, from the card to the PR

## At a glance

Nothing waits for a person: no approval of the plan, no signature, no «ok, continue». Each step closes with a command and the
next starts only if it exited 0. It can be guaranteed that something ran, not that its verdict is right.

- **One round of questions:** every open `<ID>-AMB-NN` in a single Jira comment, in the business's language without IDs or
  jargon, with the option assumed if nobody answers; answers are read at two fixed points (before the red tests, before the
  plan); the unanswered become `<ID>-ASM-NN`. Never a second round: a later doubt is an `ASM-NN` listed in the PR.
- **The close publishes only:** the card's branch, a PR ready for review with `closing.md` as body, the CI result as a comment,
  the closing comment on Jira. Never main, `--force` or a merge (`publish.mjs` blocks them).
- **What the close needs is awaited:** by the notification of the background command or a subagent that waits; the turn does
  not end with it pending.
- **A step that cannot run** (no remote, `gh`, Jira MCP, CI) is *could not run*, named in `closing.md`; nothing is invented, and the
  card is not given as passed. An uncorrected finding stops the close. No check is turned off: it stops the card.
  No remote: `publish: could not run, no remote configured`.
- **The PR always lists:** the live `ASM-NN` and how many expired unanswered, late answers not applied, the snapshot still
  `proposed`, that the visual verdict was a model's, and any review finding left uncorrected.

Read the rest only when an answer arrives after the deadline, the card has no remote or no Jira, or `SDD_UNATTENDED=1` blocks `kit.mjs off` or `grade`.

## The mode

People create cards in Jira and review the PR; everything in between is done by Claude. There is
one mode, not two: nothing in the method waits for an approval, a signature or an «ok, continue».
This document says **how that is achieved** and, above all, **where it stops being achieved** —
because the failure this method exists to avoid is saying something was verified when it is not
known.

## The rule that orders everything

> **It can be guaranteed that something ran. It cannot be guaranteed that its verdict is
> correct.**

Some validations are decided by an exit code and some by parsing the output: they are mechanized
in full (`.claude/reference/validate-mechanical.md`). The judgment items of `/validate` need
someone to read a report and give an opinion: for those, it is guaranteed that the report was
produced and that any finding stops the card. Whether the report is right, nothing guarantees.

## Orchestration does not live in the model

**A hook cannot force the model to invoke a skill.** Hooks only inject text the model reads as a
reminder and can ignore. Nor is there a hard gate of «the session does not end until the tests
pass»: a `Stop` hook blocks up to 8 times and then the system overrides it.

The consequence: **each step closes with a command, and the chaining reads exit codes.** Nothing
depends on the model remembering the next step.

```
for each card in the queue:
  /card <ID>                → fails: the card could not be read          → stops, nothing is published
  the ten questions         → ends with ONE comment on the card (all the questions)
  /scenarios <ID>           → reads the answers; fails: the tests do not end up red
  the plan of <ID>          → reads the answers again, the last time; fails: no File map
  steps 6-9 of <ID>         → the main thread; with 15+ production files in the File map (bar.mjs --route)
                              or the 230k warning: handoff.md, then the conductor returns with closing.md committed
  /close <ID>               → a validation red: back to actions.md, until the cap
                            → otherwise: push, PR, CI, Jira (below), with the three states
```

**The next step starts only if the previous one exited 0.** That is a shell `if` or a hook, not a
judgment of the model.

## What is deterministic inside the session

`PreToolUse` with exit 2 **blocks the tool**, and the model cannot get around it. That is where
what cannot depend on good will goes: the hooks listed in `CLAUDE.md`, «What does not depend on
your good will».

The guard does not use a state file to freeze a committed tagged test: it asks git. **The freezing
of step 4 was already a commit** — the guard only enforces it. The guard **fails closed**: if it
cannot read the file or query git, it stops.

`publish.mjs` does the same for publishing: it reads the card's own files (`ambiguities.md`,
`closing.md`) and git, and it fails closed. The remote's branch protection is the layer no local
command can dodge: it is recommended, and its absence is not something the hook can fix.

## What the close needs is awaited

*Measured, three times:* a run sent the validations to the background, wrote *“I'll continue when
they finish”* and **there was no when they finish**. The rule: **what the close needs is awaited**
—by the notification of the background command, or by a subagent that waits for you and returns
with the output— and the turn does not end with it pending (`no-pending-close.mjs`). To the
background goes what you can abandon without the result changing, and what you do wait for, with
its log: the suite, the mutation, `gh pr checks --watch`. Never a polling loop.

## The one round of questions

**Always on the card in Jira, once, without asking approval.** Whoever set up the run gave it: the
comment is part of the method.

1. **When step 2 ends**, every `<ID>-AMB-NN` that is `open` goes in **a single comment**
   (`addCommentToJiraIssue`, the card's own key). Each question is written in the business's
   language, without IDs or jargon, numbered 1…n, with its options and the one that will be assumed
   if nobody answers. It says when the answers are read: before the tests and, for the last time,
   before the plan. The hook records `<ID>-ASK · <date> · posted` in `ambiguities.md`, and each
   `AMB-NN` gets `asked · question <n> of the single comment`.
2. **Answers are read from the card's comments at two fixed points**, never by waiting: before
   freezing the tests in red (`/scenarios`) and before writing the plan (`steps/05-plan.md`).
   Each answered one becomes `<ID>-AMB-NN · <date> · resolved · <answer> · <author>, <date>`.
3. **The deadline is the second reading.** What has no answer then is `<ID>-AMB-NN · <date> ·
   expired → <ID>-ASM-NN`: an assumption in the interpretation that works with any answer or,
   failing that, the cheapest to undo, with its test tagged `@assumption:<ID>-ASM-NN` or declared
   uncovered. An answer that comes after, or that contradicts an assumption already frozen in a red
   test, is not applied (the guard does not allow touching the frozen tests): it is listed in the PR
   with what undoing the assumption costs.
4. **There is never a second round.** A doubt that appears while implementing goes straight to
   `ASM-NN`, with its test, and is listed in the PR. `publish.mjs` blocks a second comment of
   questions. A failed post is released once: append `<ID>-ASK · <date> · failed · <error>` and
   post again; if it fails again, the channel does not exist.
5. **No channel** —the card did not come from Jira, there is no MCP, the post failed twice, the
   answers cannot be read—: each ambiguity collapses into one event,
   `<ID>-AMB-NN · <date> · no channel · <the question> → <ID>-ASM-NN`, and the PR says so. If only
   the reading fails, what was not read expires at the second point and the PR says the answers
   could not be read.

## The close publishes, and only that

After the validations (`/close`), with `closing.md` written, in this order. The main thread does
it, because what the PR and the comment say is what decides; the waiting for CI goes to a
subagent or to the background with its log.

1. **Branch.** The card's branch is named like its folder, `<ID>-<short-slug>`, and `/card` creates
   it. `git push -u origin <branch>`: only that branch, never `main` or the default branch, never
   `--force`, `--delete`, `--all`, `--mirror` or tags.
2. **PR.** `gh pr create`, ready for review (not a draft), against the default branch, with
   `closing.md` as its body: the three states (passed · failed · could not run), the `ASM-NN`
   with their tests, the questions that stayed unanswered, and the link to the card. The snapshot
   is still `proposed`, and the PR says it: **the review of the requirement and of the code is
   the person's, on the PR.**
3. **CI.** If the repo has it, `gh pr checks --watch` with its log, in the background or in a
   subagent; the result goes on the PR as a `gh pr comment`. A red CI is reported as is.
4. **Jira.** The closing comment on the card, with the link to the PR. `publish.mjs` records
   `<ID>-CLOSE · <date> · posted`.
5. **No merge.** `gh pr merge` is blocked.

**Each step that cannot run —no remote, no `gh`, no MCP of Jira, no CI— is *could not run*,**
named in `closing.md` and, if the PR already exists, in a comment on it. **With no remote (`git remote` empty)
the push and the PR are not attempted** —`publish.mjs` refuses them and prints the line—: `closing.md` gets, under
`## Could not run`, `publish: could not run, no remote configured (git remote is empty)`. The card closes locally
all the same and nothing is invented: not a PR URL, not a CI result. **A card with anything in
*could not run* is not given as passed**; the PR says exactly what did not run.

## The three things no mechanism solves

They are points where the method asks for a judgment that does not exist if nobody is there.

**1 · The ambiguity nobody answers.** With nobody on the business side, *every* ambiguity
expires and becomes an assumption. The record remains honest —what was assumed and why stays
written— but it stops being a control mechanism: it becomes an automatic stamp. **The more
assumptions a card accumulates, the less its green says.** The count of live assumptions heads
the PR: many assumptions on a small card is the headline, not a detail at the foot.

**2 · The snapshot nobody signs.** `status: proposed` stays so on every card, and the PR says that
the requirement was transcribed by a model and read by no person yet. Nothing waits for the
signature; the person who merges is the one who gives it.

**3 · The screen nobody looks at.** *Measured:* a model with the brief detects 3 of 5 real phone
defects; a person, 5. The two that escape are typographic judgment and nested hierarchies. The
capture strip and the model's reading of it are produced; **the missing 2 of 5 is covered by
nobody until someone opens the PR.**

## What it does on reaching a limit

**It does not give the card as passed and does not lie.** *Could not run* and *nobody checked it*
are the same state —“I don't know”— and neither is passed. A failed validation goes back to
`actions.md` and is corrected, not published as if it were fine. When the card's cap runs out with
something still failing or unrun, it is published as such —the PR is where a person reviews it—,
under `## Failed` or `## Could not run`, with the exact detail of what and why.

The closing, the PR and the Jira comment always list, even if everything is green:

- the live `ASM-NN`, and **how many expired unanswered** instead of being resolved;
- the answers that came after the deadline and were not applied;
- that the snapshot is still at `proposed`;
- that the visual verdict was given by a model and not a person;
- any finding of `/code-review`, `/design-review`, `/accessibility-audit` or `/design-deslop`
  that was not corrected.

**An uncorrected finding stops the close.** A run that executes the review, writes the report and
closes anyway produces the evidence that something was wrong and files it away.

## The escape valve does not exist

Turning off a check nobody understands in a minute would give **the same actor that is blocked the
power to disable what blocks it**, with nobody to object. A check that stops is not turned off: it
stops the card, and the card is reported with what it lacks.

## Modules and grade: what only a person decides

`SDD_UNATTENDED=1`, exported by whoever runs a card with no person deciding, is the safety limit
of this mode and it is not about publishing. With it, `node .claude/tools/kit.mjs off` exits 2, and
`confirm-off` too above poc (at poc it passes and leaves `<ID>-ASM-NN · <date> · module <module> kept
off at poc: signal <s> · undo: kit.mjs on <module>`, since it turns nothing off): the module that is
off stays off by a person's decision, and a signal that came after it (`require-bar.mjs` blocks the
plan; `required.mjs` reports it at the close) is not the agent's to dismiss. What it does is the
cheapest thing to undo: `node .claude/tools/kit.mjs on <module>`, which leaves the event
`<ID>-ASM-NN · <date> · module <module> activated: signal <s> · undo: kit.mjs off <module> --reason …`
in `ambiguities.md`. What was done with more checks stays valid if a person later turns the module
off again; the reverse would need an inspection again. The extra time counts against the card's
cap; if it does not fit, the PR says what was left.

The grade works the same way: with `SDD_UNATTENDED=1`, `node .claude/tools/kit.mjs grade` exits 2
for `poc` and for any grade below the one the repo has (production when none is recorded), because
a lighter bar is a person's decision; raising it passes.
