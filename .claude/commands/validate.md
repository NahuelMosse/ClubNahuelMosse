---
description: Runs the step 8 reviews over what was implemented — suite, test quality, code, security, accessibility, cost of the next change and clean-context review.
argument-hint: <CARD-ID>
---

Card: `$1`. This is the whole of step 8. When everything is answered, `/close $1` writes the close.

## At a glance

One verification batch, one verdict, one list of actions fixed at once. Everything goes out together, in one
message: `node .claude/tools/verify.mjs` in the background with its log, the `inspector`s that `inspectors.mjs`
says, `/code-review` over the card's repo and base (`review-range.mjs`), and what the case adds
(`.claude/reference/validate-cases.md`, «Launching the batch»). Each item ends in one of four states —`passed`,
`failed`, `could not run`, `not applicable` (the reason comes from the requirement)— with its output pasted; only
`passed` closes.

Every failure goes to `specs/<card>/actions.md`, one line per finding, fixed in one `implementer` commit:
```
ACT-NN · <criterion ID> · <H|M|L> · <what fails and how to reproduce it> · close: <what has to come out right, not how to fix it> · open|suspect
```
It becomes `closed · <output of its close condition>`; none closes without it. `suspect` is a judgment finding with no
failing command: all of them go to one `CONFIRM-SUSPECT` call. `verify.mjs` runs complete at the start and once more when
no action is open. A new test file with this card's tags after the freeze needs, in `ambiguities.md`,
`<ID>-TESTS · <date> · refrozen at pending · <reason> · <file>` before the guard lets it through, then `refrozen at <sha>`.

Most broken:
- A finding about what the card did not create or change is an action: it is `OUT` or `AMB`.
- Closing over `failed` or `could not run`; a tool that cannot be reached stays `could not run`, with the error pasted.
- A second round of judges, or a second `verify.mjs` between rounds.
- An action that says how to fix instead of what has to come out right.

Read the rest only when you answer a judgment item the plan's bar marks as case-only (T7, T8, G5 to G7, A7, M2 to M6, F3 to F5) or launch a judge that a screen or a long diff adds.

## Before starting

**The mechanical items —suite, mutation, linters, analyzers, attacks, axe, endurance— are run by
`node .claude/tools/verify.mjs`; their list, with the command and what passing means, lives in
`.claude/reference/validate-mechanical.md`.** This file has the batch procedure and the items that
are judgment; what applies only in a case (a screen, an enumeration, a shared app, a finding) is in
`.claude/reference/validate-cases.md`, each section with when to read it. The commands of each item are in
the stack profile, `.claude/stacks/<stack>.md`; if the repo has none yet, choosing it is part of this card.

**Each item is answered with one of four states and its evidence:**

| | |
|---|---|
| `passed` | the command gave what was expected — paste the output |
| `failed` | it did not give what was expected — **do not close** |
| `could not run` | it does not exist, did not start, did not run — **does not count as passed** and **do not close** |
| `not applicable` | the feature does not exist in this product — **the reason comes from the requirement**, never from “it is small” |

## A single verdict

After the code there is **a single verification batch and a single verdict**: one list of actions
that is fixed once. There are no stages that find things separately and trigger separate rounds.

1. **Everything goes out together, in a single message, without touching code**, and nothing
   waits for anything else. What can pass ~30 s goes to the background with its output to a log, read when the
   notification arrives: no `sleep` or `until grep …` loops; meanwhile you do other work.
   - `node .claude/tools/verify.mjs > .validation/verify.log 2>&1`, **run by you in the
     background** —not through a `runner`: its log is already the list of actions—. It runs the
     commands of the plan's `## Verification` in parallel, with `once.mjs`, and then `required.mjs`: the mutation of **each
     production file in the diff** and the linter of **each test in the diff**. It is the first complete run of the card;
   - **the `inspector`s that `node .claude/tools/inspectors.mjs` says** —F6—, almost always one, launched
     with the card folder, the commit the card starts at and its criteria IDs. Each answers F1 first in its
     `inspection.md` and reviews the diff; the mechanical part is `verify.mjs`'s;
   - `/code-review` —C1— in the same message, **over the card's repo and base, not the session's directory
     nor `main`**: `review-range.mjs <card folder>` prints both and the diff command;
   - **what the case adds** (an `app:` line, the verdict `reviewer`, `design-review`, `accessibility-audit`, R1 the p95, a quiet
     subagent, a long diff): `.claude/reference/validate-cases.md`, “Launching the batch”, read before launching.

   While everything comes back, answer the judgment items that are yours.
   **The turn does not end with the log or an agent pending** (`.claude/AUTONOMY.md`).
2. **The reports are saved as they came back** —`specs/<card>/inspection.md`, `code-review.md` and `review.md`, if it ran—.
   **Everything that failed, wherever it comes from, goes to `specs/<card>/actions.md`**, one line per finding:

   ```
   ACT-NN · <ID of the criterion, item or review> · <H|M|L> · <what fails and how to reproduce it> · close: <the command or the steps that have to come out right> · open|suspect
   ```

   **The close condition says what has to happen, not how to fix it** (“`attack.mjs` with `--read /clientes.csv`
   exits with 0”). The same defect found by several sources goes once, with the most specific
   criterion. **That is the verdict: the whole list, together.** The inspectors, the `reviewer` and `verify.mjs`
   return each failure **already as an `ACT` line**: you paste and deduplicate, you do not rewrite.
   Classifying a finding, what reopens the card and what is not an action: `validate-cases.md`, “Classifying a finding”.
   **A finding about what the card did not create is not an action** (`OUT` or `AMB-NN`). A G or M action is confirmed
   by its test and `verify.mjs`, not by a second lap of the inspector, which runs once per close.
3. **The whole list is fixed at once**, in a single commit, by an `implementer` —two in parallel only if their
   actions do not touch the same files or share a decision; with 12 or fewer production files, a `SendMessage`
   to the last one—, which receives the path of `actions.md`, not the conversation. Each line becomes `closed ·
   <the output of its close condition>`; none is closed without that output. **A finding about what the card
   created or modified is not closed as `OUT`**, and “could not run” carries the error output pasted in.
4. **`verify.mjs` is run again, once**, when `actions.md` has no open action and the last group of 6-7
   finished; in between each round's `implementer` runs only what is bounded to what it touched. No second batch
   of judgment, except the judges' second lap —only if some `ACT` closes with something that is not a command,
   or the File map names 15 or more production files—, before this `verify.mjs`.

The screen suite is run once per card, over the final code, by `verify.mjs`; while implementing, only the unit tests and this
card's scenarios, bounded (`validate-cases.md`, “The cost of the screen suite”). Why each item is there:
`.claude/reference/why-validate.md`, `.claude/reference/why-verify-step.md`.

## The judgment items

Items that apply only in a case —T7, T8, G5 to G7, A7, M2 to M6, F3 to F5— are in `.claude/reference/validate-cases.md`.

**Pause 2 · What the suite does not see even when green**

- [ ] **T2** Each business rule has a test **that does not launch a browser**.
- [ ] **T4** **Derive what you traverse; never derive what you assert against** — in the e2e too.
- [ ] **T5** No assertion satisfies itself: no `> 0` nor “not empty”, none behind an `if`, and the test's name does not promise more than it asserts.
- [ ] **T6** Every number promised in a text —README, comment, screen— is pinned by a test.

**Pause 3 · The code**

- [ ] **C1** `/code-review` over the card's repo and base (`review-range.mjs`): bugs, reuse and simplification; `/simplify` is not run separately. A long diff is split, and a screen or component also gets `design-review` and `accessibility-audit` (`validate-cases.md`).
- [ ] **C3** No result type carries a value when it fails.
- [ ] **C4** A missing key of a closed enumeration **throws**; it does not fall to a default value.
- [ ] **C7** Everything that comes in from outside —file, local storage, response— is validated on the way in. Parsing is not validating.

**Pause 4 · Security**

- [ ] **G1** **The ASVS 5.0 level 1 matrix** —`.claude/templates/asvs-level-1.md`— lives in the repo, in `specs/asvs.md`, answered row by row with the four states; the first card creates it. **Each card answers again only the chapters its diff touches** (which ones: `validate-cases.md`) and leaves the rest as it was.
- [ ] **G8** Nothing from production on the agent's machine, and **no test data comes from real data that is not anonymized**.

**Pause 7 · The next change**

- [ ] **M1** Three to five **plausible changes fixed before looking at the code** —one more member in the enumeration, one more field, one more filter— and for each one, the files to touch **counted with a command**, searching by name **and by quantity**. Four or more: the rule is copied and it is fixed here.
- [ ] **M7** The number from M1 stays in the close, so that the next card sees whether it is rising.
- [ ] **M8** No function that only forwards —its body is a call to another with the same arguments— and no module that exposes more than it hides.

**Pause 8 · Before the close**

- [ ] **F1** **Does it do what the card asked**: the `inspector` (and the `reviewer`, for a screen or a route that writes) answers, against the running app, each acceptance criterion `meets · fails · not verified`, and lists what the card did not ask for.
- [ ] **F2** What is missing for **what this card touched** to be impeccable **is fixed here or asked as `$1-AMB-NN`**. A ceiling is only a ceiling if the business set it. What is wrong **outside** it stays as `$1-OUT-NN` with file, line and severity.
- [ ] **F6** **Inspection with every criterion of `.claude/reference/criteria.md`**, the list the bar went through: `verify.mjs` answers the mechanical ones, the `inspector`s that `inspectors.mjs` says the judgment ones (`.claude/templates/inspection.md`), in the same batch. Failures go to `actions.md` like any finding. **It closes with all applicable criteria at `meets` and no open action.** A criterion that a business constraint prevents is `AMB-NN`, never a failure accepted in silence.
