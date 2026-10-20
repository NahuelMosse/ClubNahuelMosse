# Step 8 · A single verdict

## At a glance

Run by whoever does steps 6 to 9: the main thread, or the conductor on a big card (`bar.mjs --route`); `/validate <ID>`
has it in full. In **one message**: `node .claude/tools/app.mjs up` first, when the plan has an `app:` line, then `node .claude/tools/verify.mjs` in the
background with its log, the `inspector`s that `inspectors.mjs` says (it prints the IDs of each group; its prompt carries those IDs),
`/code-review`, the verdict `reviewer` if the card has a screen or a route that writes, and with a screen the first lap of the visual
judges, complete, plus **a `reviewer` of its own for the blind comparison (prompt `PAIRWISE`) over the pairs `app.mjs pairs <base> <steps.json>`
captures** (`<base>` is `review-range.mjs --base`; X/Y at random, the key in `.validation/pairs/key.json`; the pairs always use the card's `steps.json`,
never a file of your own; a base with no screen at the route, or that does not show the first `wait` or `click` of the steps, gets `pairwise.md`
«not applicable · no previous screen at <route>» and no reviewer; the visual judge cannot launch agents, so it has none).
`/code-review` runs once, in this message, at `medium` (`high` on a high-risk card), with the args `review-range.mjs` prints plus "decided,
do not report: `## Assumptions` of plan.md"; its findings join the one `actions.md` round and their `ACT`s close them.
Each report has one owner: the inspector writes `inspection.md` and `accessibility.md` (its prompt says which F1 rows it covers), the
verdict reviewer `review.md`, the visual judge `judge.md`, `screen-audit.md`, the captures and the motion-audit, the `PAIRWISE` reviewer
`pairwise.md`; you save `/code-review` as `code-review.md` (`close.mjs` check 18, which also wants its lap in `.git/sdd-reviews.json`).
`required.mjs` names the owner of each missing one; while that agent runs it is `pending`, not an `ACT`.

First line of each judge's prompt: `VISUAL-JUDGE <ID> · the brief and the strips · write judge.md and
screen-audit.md` (audit template: `.claude/templates/design-line.md` section 6b); `PAIRWISE <ID> · the X/Y pairs of .validation/pairs · write pairwise.md`;
`CONFIRM-SUSPECT <ID> · the suspect ACT lines · one line each` (and `RED-REVIEW <ID> · …` in step 4). The prompt of the inspector, verdict reviewer and visual judge ends: «first call `help.mjs judge`, second
`judge-context.mjs <inspector|reviewer|visual>`; do not read the tools' code».

**One wait per lap**, for the log and the judges together: `node .claude/tools/wait.mjs .validation/verify.log --agent <id> --agent <id> --all --max 570`
(one `--agent` per judge in the background).

Every failure in what the card created or changed goes to `specs/<card>/actions.md` as an `ACT-NN` line; one combined `implementer`
round fixes them (on a small card, a `SendMessage` to the last implementer), and it writes `closed · <output>` on each line it fixed:
you verify with `close.mjs` (checks 10–11), without running the commands again. When every line is closed the implementer runs `verify.mjs` complete once and, with a
screen, the registry of captures (`once.mjs captures -- node .claude/tools/app.mjs probe <steps.json> …`), and its report ends with their last lines:
read them and **do not re-verify by hand** (no `verify.mjs`, `app.mjs up`, probe or capture of your own) unless one says it failed. Then the judges' second lap, **only** if some `ACT`
closes with something that is not a command or the File map names 15 or more production files; a lap that finds something makes that run stale, and the final complete `verify.mjs` and the captures are then yours, after it.
A fix after a report is an `ACT` line closed with its output, never a question to its judge — inspector and verdict reviewer are not
resumed with SendMessage: idle past five minutes, they rewrite their whole context. The second lap of a `VISUAL-JUDGE` is a new launch,
prompt `CONFIRM` and the `ACT` lines.
The line, one per finding (the tools return it already written: paste and deduplicate):
```
ACT-NN · <criterion ID> · <H|M|L> · <what fails and how to reproduce it> · close: <what has to come out right, not how to fix it> · open|suspect
```
It becomes `closed · <output of its close condition>`; none closes without that output. A judgment finding whose proof is
not a failing command enters as `suspect`, and all of them go in one `CONFIRM-SUSPECT` call (`agents/reviewer.md`). A G or M
action is confirmed by its test and `verify.mjs`, not by a second lap. The L actions of one file that are visual or
documentation go as one action.

A fix that needs a new test file with this card's tags after the freeze is blocked by the guard until `ambiguities.md` has
`<ID>-TESTS · <date> · refrozen at pending · <reason> · <file>`; after committing it, append `refrozen at <sha>`.

**Closes with:** the `verify.mjs` log ends in `Nothing to fix`, and
`grep -cE "· (open|suspect)$" specs/<feature>/actions.md` gives 0.

Most broken:
- Launching the judges one after another, or fixing what `verify.mjs` found before launching them.
- A complete `verify.mjs` between rounds: the implementer runs only what is bounded to what it touched, and the complete one once, when it closes its round.
- An action for what the card did not create or change: it is `OUT` or `AMB`; what the card did create is never `OUT`.
- «It is small» or «there is no time» as the reason to leave a finding: it is fixed or asked as `AMB`.
- Waiting with `sleep` or `until grep`: `wait.mjs` on the log.

Read the rest only when the card is high risk (money, personal data, permissions, something irreversible) or a finding is in old code the card did not touch and has to be recorded as `OUT`.

## Full rules

`/validate <ID>` runs it in full. In short:

1. **The mechanical part, at once:** `node .claude/tools/verify.mjs` launches in parallel
   everything that is a command —the suite, the mutation and the linter for what the card
   touched, the attacks against the routes, axe over the screens, the greps of `/close`— and
   returns a list of actions. What already passed over the same code is not repeated, and a line
   another line includes (`web` inside `suite`) is reported `covered by <line>` and not run. The
   fast lines go first; the Playwright ones start only if those passed. A suite that fails with at
   most 3 tests gets only those re-run ×3: `passed with flaky k/3 <test>` is a pass that stays
   visible —listed in `.validation/verify/flaky.md`, and in `closing.md` under `## Passed`— and
   3 of 3 stays red. You launch it yourself, not through a `runner`, **in the background with its
   output to a log** (`.validation/verify.log`): the log is already the verdict, and you wait with
   `node .claude/tools/wait.mjs .validation/verify.log --max 570` (verify ends its log with the fixed line
   `verify: exit <N> in <X> min`: 0 is clean, 1 is a wait that ends with actions to read) or by the notification, never with an `until grep …` loop nor a long `sleep`, and meanwhile you
   do the other work (`mutate.mjs` the same). The list of what it runs is
   `.claude/reference/validate-mechanical.md`.
   **One complete verification per chain of corrections.** It runs complete at the start of this
   step, and once more when `actions.md` has no open action and the last group of 6-7 finished —by the implementer that
   closes the round—: not in between. During the rounds of `actions.md` the implementer runs only what is bounded to
   what it touched: the affected specs and unit tests (`node .claude/tools/affected.mjs <files it
   touched>` lists them), lint and tsc, the mutation of the `rule` files it touched. With a screen,
   the visual judges' second lap goes before that last `verify.mjs`, not with it.
2. **The judgment, in proportion:** the `inspector`s that `inspectors.mjs` says —almost always
   one— over the **applicable criteria that are judgment**, which also answer F1 —whether the
   product does what the card asked, against the running app— and review the diff. `reviewer`, in
   a clean context —the **verdict reviewer**—, only if the card creates a screen or a route that writes;
   it goes out in the message of the inspector and `verify.mjs`, before any correction, and its findings
   join theirs in one `actions.md` round (`review-cap.mjs` refuses the implementer's round of `actions.md`
   while `review.md` is missing). `design-review` and
   `accessibility-audit` only if it creates a screen or a component, and in a subagent. At grade `poc`
   neither the `inspector` nor the `reviewer` runs (`inspectors.mjs` says 0); `mvp` and `production` run both. The criteria
   of a module that is off are not judged: the bar answered them with its line `<module> · off by
   decision · <reason>`, and each active module's part is its `## Step 8` in `steps/m-<module>.md`.
3. **Every failure in what the card created or changed goes to `actions.md`** —the rest is `OUT` or
   `AMB`, below—, is corrected at once, and `verify.mjs` is run again. A G or M action is confirmed by
   its test and `verify.mjs`, not by a second lap of the judge: the `inspector` runs once per close
   —as many launches as `inspectors.mjs` says, one lap— and `review-cap.mjs` stops the next. The verdict
   `reviewer` has a second lap only if some `ACT` closes with something that is not a command (a look, a capture)
   or the File map names 15 or more production files (`secondLap` in `tools/card.mjs`); `review-cap.mjs` refuses it
   otherwise. The round of `actions.md` of a small card (12 or fewer production files) goes by `SendMessage` to the
   last implementer; a new one only if that one is not available.
   A judgment finding whose proof is not a failing command enters as `suspect`; all of them go
   together, in one `CONFIRM-SUSPECT` call, to a second judge in a clean context (how:
   `.claude/agents/reviewer.md`).

**One app for every judge.** With an `app:` line in the plan, `node .claude/tools/app.mjs up` runs
before that message and its `APP_URL` goes to the inspector, the `reviewer` and the visual,
accessibility and `CONFIRM-SUSPECT` judges: they use it and start no other. It need not come down
before the implementer's round: the next `up` renews it if the code changed. `/close` runs `down`.
The inspector tests the acceptance criteria; the verdict `reviewer` concentrates on the extra, the
error flows and a user's eyes, and cites a criterion as tested by the inspector only if its message
says the inspector covers it. Who tests a criterion changes, never whether it is tested.

1 and 2 go out **in a single message**: `verify.mjs` in the background and the judgment agents in
the same message. **Neither waits for the other**: the inspector does not need the output of
`verify.mjs`, and fixing what `verify.mjs` found before launching the judgment adds a whole lap.
**With a screen, the visual judges of step 9's first lap (module ui) go in that same
message**, with the inspector and the `reviewer`: all their actions go into one `actions.md`
and there is a single combined `implementer` round. **The judges' second lap**, the one that verifies
the fixes, exists only under the same two conditions (an `ACT` that no command closes, or 15 or more production
files); it runs after that round and **before** the final `verify.mjs`, never beside it: if it finds
something, that verification is already stale. The cap of laps (`review-cap.mjs`) does not change.
The turn does not end with the log or an agent pending (`.claude/AUTONOMY.md`).
**One browser run at a time:** `once.mjs`, and so `verify.mjs`, mark a Playwright run in `.git/sdd-browser-run.json` (PID and command); `guard-shell` refuses another command that launches Playwright while that PID lives, because both write `test-results/`. Wait for it with `wait.mjs`.

**Cosmetic actions are not dropped, they are grouped.** The L actions of the same file that are
visual or documentation —a spacing, a label, a README line— go in `actions.md` as **one** action
per file, so the implementer does them together and they cost no extra round.

The `inspector`s write `specs/<card>/inspection.md`, F1 first; `reviewer`, when it runs,
`specs/<card>/review.md`; the `/code-review` report is saved as `specs/<card>/code-review.md`.

**The evidence, in proportion to what the card touches:** ASVS rows only for the chapters the diff
touches —none without new inputs, outputs or data—; the accessibility report is complete for a new
screen, and for a changed one a line per WCAG criterion the change brings into play.

**The default command has to run everything that counts.** It is the one that will be run by
whoever read nothing. Why each rule of this step is there: `.claude/reference/why-verify-step.md`.

## What is fixed and what is not

**What is missing for this to be impeccable has two destinations:** it is fixed in this card, or
it is asked as `<ID>-AMB-NN`. “It's small” or “there isn't time” are the decision not to do it.

**“This” has an edge: what the card touches.** Inside go the files of the map and, within them,
the functions the card changes and their tests. **Outside stays everything else, even if it is
wrong**: it is recorded as `<ID>-OUT-NN` in `ambiguities.md` with the `file:line` of the code as
it was when the card started and its severity, and goes to the close as a card of its own.

- **What the card did not create or change is never an action**, not even a missing protection or
  a new capability: `OUT` (README “Known issues” if H or M) or `AMB`; `required.mjs` flags it.
- **What the card created or modified is never `OUT`**, even if the same defect exists in old
  code. `required.mjs` checks it: an OUT that points to a changed line, to a modified function or
  to a call to a modified function does not let the close happen. If the card ended up touching
  what had been recorded as OUT, it is withdrawn with an event at the end of the record:
  `<ID>-OUT-NN · <date> · withdrawn · <reason>`, and the defect is fixed in the card.
- **An old function that the card modified belongs to the card in every place where it is
  used.** If that is too much, it is not modified: a new one is written for the card's part.
- **Changing how the app starts or is deployed** —which interface it listens on, which host names
  the whole app accepts— is an `OUT` unless the card asks for it. The defense goes on each route
  the card created or modified and accepts what the app already answers; the exact recipe (Host,
  body cap, aborting client, log of a 500) is in `steps/m-api.md` (module api), Step 6 · Implementing.
- **“Prevents” means that without fixing it an acceptance criterion is not met.** A tool that
  cannot be reached does not prevent the card: the item stays `could not run`, with the error
  output pasted.

**If the card is high risk** —money, personal data, permissions, something irreversible—, the
rigor goes up: ASVS level 2 (`.claude/templates/asvs-level-2.md`, module security-l2), and the PR
says it is high risk, for whoever reviews it. **The level adds checks; it never removes them.**

→ **Before closing, look at the diff against the card: what is here that was not asked for?**
`/close <ID>` writes the comment for the client **only** from what the validations said.
