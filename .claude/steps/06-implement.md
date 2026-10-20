# Steps 6 and 7 · Implement, and make the diff do what the plan said

## At a glance

Steps 6 to 9 are the main thread's; on a big card (15 or more production files in the File map, `bar.mjs --route`,
or the 230k warning of `context-cap.mjs`) they are the `conductor`'s, by `handoff.md` (`steps/05-plan.md`), and
it reads this document. Whoever runs them launches one `implementer` per group of the plan's `## File map`,
in order, each with a fresh context and a short prompt that points at files; **with 12 or fewer production files,
a single `implementer` does every group in order**. It writes the code and the card's evidence against the bar,
verifies bounded, and returns. Step 7 compares the diff with the map.

**Closes with:** `git diff --name-only <tests-commit>..HEAD -- $E2E` comes out empty, and
`git diff --name-only <card-base>` (`node .claude/tools/review-range.mjs --base`) matches `## File map` in both directions.

Most broken:
- An `implementer` or a `grunt` running a whole suite, or `verify.mjs` before the round of `actions.md` is closed: only what is bounded to what it touched.
- A prompt that pastes the plan or the tests: it points at files (the template below; over 3000 characters `review-cap.mjs` warns).
- A frozen scenario test edited: the implementer reports the defect; refreezing is an event, never a quiet edit.
- Scope beyond the map: an extra control or endpoint is an `<ID>-OUT-NN` proposal, not code.
- A `rule` file without its test committed in red first.
- Tool output you keep (a `help.mjs` listing, a log) goes to `.validation/` of the card's repo, never outside it: a fixed path elsewhere is overwritten by another run.
- Waiting with `sleep`, `until grep` or a guessed `--until`: log and `wait.mjs <log> --max 570` (kit tools end it with `<tool>: exit <N> in <X> min`); an agent, `wait.mjs --agent <id> --max 570`.
- An implementer that edits a file ten times or reads by shell.

The prompt to an implementer points at files and never pastes them; fill the angle brackets, nothing more:
```
Group <N> of specs/<card>/plan.md (## File map): <group name>.
Read first, yourself: specs/<card>/handoff.md, card.snapshot.md, ambiguities.md,
then the plan's ## Bar, ## Edges and the rows of this group.
Tests in red for this group: <spec files or tags>. Do not touch them.
Rules to read, by ID and line range: <IDs from the plan>.
Checklist: node .claude/tools/bar.mjs <criteria IDs of the plan>.
Previous group: <commit or report path, one line>.
Only bounded checks: no verify.mjs, no whole suite. Return when the group is green:
files written, the lines of your checks, scenarios and ASM covered, what is open.
Your last message is the whole report.
```
With 12 or fewer production files, list every group in the one prompt; the round of `actions.md` goes by `SendMessage`.
Every prompt adds «Do not read verify.mjs; its messages name what is missing.» With a screen (not at poc), before launching, copy the
set unless it exists —copy only what the page loads (`tokens.css`, `primitives.css`, `components.css`, `fonts/*.woff2`,
`NOTICES.md`) from `.claude/templates/components/*` to `design/components/` (module ui), not the folder—; the server serves `design/` by extension
(`.css`, `.woff2`) with a test that `/design/line.md` is 404; the File map names the copied set as one line
`design/components/ — copied from the kit`. Add «Read `templates/design-line.md` and `rules/interface.md` yourself» (module ui): you read neither.

Read the rest only when a group hits the context cap, a frozen test has to change, or the card has an `RFZ`.

## Who writes the code

- **The code is written in a single thread, and it is not the caller's** (main thread or conductor). The `implementer` writes it, with
  the paths of `card.snapshot.md` and `ambiguities.md`, `plan.md`, `handoff.md` if there is one, the tests in red and the IDs of
  the judgment criteria the bar applies —its checklist, from `node .claude/tools/bar.mjs <IDs>`—,
  not with the conversation; it returns the files it wrote, the output of its checks, the
  scenarios and `ASM-NN` its group covered and what it could not close. The caller decides and
  reviews: it does not read the code it did not need to judge.
- **One `implementer` per group of the plan's `## File map`**, launched by the caller in
  order —domain/logic, then interface, then the tests' support—, each with a fresh context: the
  plan, the tests of its group and the summary of the previous group. It returns when its group
  is green with its checks; it does not start the next one.
- **With 12 or fewer production files in the File map, one `implementer` does all the groups in order**
  (the same prompt, listing every group): the groups are still the map's order, and it returns when the last is
  green. The round of `actions.md` goes to it by `SendMessage`; a new `implementer`, with the plan and `actions.md`,
  only if it is not available. `review-cap.mjs` still asks for `review.md` before that round.
- **An `implementer`, a `grunt` or the `conductor` has a context cap.** `hooks/context-cap.mjs` estimates it from the last assistant
  message of its transcript (input, cache read and cache creation tokens): past 250k it warns once; past 300k it refuses
  every tool but `git add`/`commit`/`status` and a Write to `specs/<card>/handoff-*.md`, and the agent commits, writes
  the handoff (what is done, what is left, files, bounded checks) and returns. **The caller then launches a fresh
  `implementer`** with the plan, the tests and that handoff, for what is left; if the conductor itself is
  stopped, the main thread launches a fresh one with `handoff.md` and its `handoff-conductor.md`. The main thread is warned
  once at 230k and not stopped: that is when it hands over. Measured: one implementer reached 303k tokens.
  Without a readable transcript the hook says nothing.
- **The scope is the card's.** The implementer builds what the plan's map and the bar name. An extra
  control, a `/health` or `/ready` endpoint, a search box, a header the grade does not require is not
  written: it is proposed as `<ID>-OUT-NN` in `ambiguities.md`. What the active criteria require is not extra.
- **What does go in parallel is what decides nothing**: reading, installing, verifying. Two
  `implementer`s at once only if their files do not touch **and** they share no design decision
  from the map.
- **Verify while writing, bounded, in every group.** No `implementer` or `grunt` runs a whole suite, not
  even through `once.mjs`: a `once.mjs` record is invalidated by any later edit, so that run saves nothing.
  They run the card's specs (by file or `--grep`), the unit tests of what they touched (`node .claude/tools/affected.mjs <group files>` lists those that import or name them), lint and tsc of those files, and the mutation of the `rule` files. The first complete run is `verify.mjs` in step 8, by the
  caller; `node --test` always carries `--test-force-exit` (`guard-shell` refuses it without). `guard-shell` refuses, inside a subagent, the whole of a plan line, the npm scripts a line
  reaches (also the parts verify splits), their literal body, `playwright test -c <config>` and
  `node --test <globs>` of a line with no spec, `--grep`/`-g` or name filter, and for an implementer or a grunt
  `verify.mjs` and a line through `once.mjs`; **except the lines named `lint`, `types` or `format` and those that
  `durations.json` or `.validation/once/` measure under 30 s**, which any subagent may run. No
  `git stash` while a run is in progress: it changes the tree under it. Long runs go in the background with their output to a log: it
  goes on with the evidence of the group or waits with
  `node .claude/tools/wait.mjs <log> --max 570` (no `--until` for a kit tool: its log ends with `<tool>: exit <N> in <X> min`)
  or the end notification, never an `until grep …` loop nor a long `sleep`.
- **In the rounds of `actions.md` the same:** what is bounded to what it touched; then, when every line of `actions.md` is `closed · <output>`,
  the implementer runs `verify.mjs` complete once and, with a screen, `once.mjs captures -- node .claude/tools/app.mjs probe <steps.json>`
  (`guard-shell` lets it only then) and its report ends with their last lines; the caller reads them and verifies nothing by hand
  (`steps/08-verify.md`).
- **A quiet subagent is chased, not awaited:** no file changed and no notification in 20 minutes,
  `SendMessage`; at 30, `TaskStop` and launch it again with its context (`steps/00-resume.md`).
- **Wait in the foreground.** A subagent the next step depends on is not sent to the background
  to later ask with `sleep` whether it finished: it is launched in the foreground, or several in
  parallel in one message.
- **The conductor does not publish.** It ends with `closing.md` written and committed, and its report; the main thread
  reads `closing.md` and `actions.md` and publishes (`commands/close.md`, «Publishing»).

## Prompt to an implementer

The template is in «At a glance». What is pasted into a prompt costs its length in the caller and again on
every request of the implementer, and what the files say is the one source of truth.

**It is written against the bar, not for the bar to correct it**, and it is delivered verified:
the implementer runs its bounded checks until they are clean before returning, and returns only then or
with what it could not close.

The evidence —ASVS rows for the chapters touched, accessibility report if there is a screen,
README decisions, docs, the API contract, the notices, the system design, the secrets inventory,
the runbook— is written by the implementer while it writes the code, so the verdict finds it done.
Each active module's part is its `## Step 6` in `steps/m-<module>.md`.
**Domain files marked `rule` start with their test**, committed in red before the code (T13): an agent
that writes the test after takes the expected value from what the code returns (`TDD-*` in
`.claude/reference/architecture.md`). How the tests are written: `.claude/reference/testing.md`.
Why each rule is there: `.claude/reference/why-implement.md`.

## The frozen tests

Whoever implements **does not touch the scenario tests**. Tests without a card tag are theirs.
The guard blocks anyone who edits a tagged test that is already committed.

**And whoever corrects freezes again:**
1. The implementer **does not fix**: it reports the defect with file, line and the minimal
   correction.
2. Whoever corrects makes the change **with the guard turned off on purpose for that**, in a
   commit that touches only `$E2E`.
3. That commit replaces the one from step 4: `<ID>-TESTS · <date> · refrozen at <hash> · <reason>`
   in `ambiguities.md`.

**A new test file with this card's scenario tags after the freeze** (added by an action of step 8 or 9 over
scenarios already frozen; never a change to the frozen ones) is blocked by the guard until `ambiguities.md`
has `<ID>-TESTS · <date> · refrozen at pending · <reason> · <file>`; after committing it, append `refrozen at <sha>`.

**A frozen test of THIS card** is changed only when step 8 found its locator wrong, with the same event and the
same conditions as for another card's, naming a tag of this card, plus an `ACT-NN` of `actions.md` in its reason whose
evidence is a critical axe finding on what the test locates or a criterion of the card that contradicts the locator
(`reason: <scenario>, ACT-NN`). The guard lets the write through only with that; the new content keeps every tag, and
once committed `<ID>-TESTS · <date> · refrozen at <sha>` closes it. Whatever else is wrong in a test is reported, not fixed.

**A test of ANOTHER card** that a requirement of this card contradicts is changed with the event
`<ID>-RFZ-NN · <file>:<test or tag> · @<other card>-H<NN>-<NN> · reason: <scenario of this card> · change: <one line>`
in `ambiguities.md`; if the other test still holds, this card is wrong.

**With nobody to turn the guard off, the gap is declared**: a missing test is not added, it is
written in `## Uncovered assumptions` and named in the close.

→ **Validate:** `git diff --name-only <tests-commit>..HEAD -- $E2E` comes out empty.

## Step 7 · The diff against the map

→ **Validate, in both directions:** `git diff --name-only <card-base>` (`node .claude/tools/review-range.mjs --base`) against `## File map`.
File in the diff that is not in the plan → undeclared scope. File in the plan that is not in the
diff → something that was not done. None is ignored.

→ **If the change was structural** —a new module, a new dependency between modules—, review it
against `.claude/rules/architecture.md`, which loads by itself and brings the concrete `grep`s.
