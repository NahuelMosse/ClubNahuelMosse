# /validate · what applies only in a case

`/validate` (`.claude/commands/validate.md`) links here. Each section says when it is read; none of it is read
for a card that does not have that case.

## Launching the batch

Read before the step 1 message of `/validate` when the card has one of these cases. They add to the message,
they do not change its order.

- **The shared app, if the plan has an `app:` line**: `node .claude/tools/app.mjs up`, run by you before this
  message, and its `APP_URL` goes to the inspector, the `reviewer` and every visual, accessibility and
  `CONFIRM-SUSPECT` judge, who use it and start no other. `up` renews it by itself when the code changed, so the
  next lap needs no `down`; the inspector tests the acceptance criteria, and the `reviewer` is told so only if
  the inspector is in the same message.
- **`reviewer` (the verdict reviewer), clean context, only if the card creates a screen or a route that writes**,
  in the same message as the inspector and `verify.mjs`, before any correction: `review-cap.mjs` refuses the
  implementer's round of `actions.md` until `review.md` exists, so its findings join one round.
- **`PAIRWISE` (the blind comparison), if the card touches a screen**, a `reviewer` of its own in that same message, over the pairs of
  captures you took with `app.mjs probe` before launching it; it writes `pairwise.md` and is counted apart from the verdict reviewer.
- **`design-review` and `accessibility-audit` if the card creates a screen or a component**, in a subagent so
  they do not take up the main thread. One more text, datum or control on a screen that already exists is
  covered by the inspector —areas I and C— and the design checks of `verify.mjs`.
- **R1, the p95**, is the only exception to “everything together”: it is measured alone at the end, because with
  other suites running the number measures the machine and not the app.
- **A subagent that changes no file and sends no notification in 20 minutes** gets a `SendMessage`; at 30
  minutes, `TaskStop` and it is launched again with its context.
- **`/code-review` of a long diff (C1)**: if the diff is longer than what the review covers at once, it is split
  by files and one review comes out per group, in parallel; the close lists each production file of the diff
  with the review that covered it, and the one no review covered stays `could not run`.

## The cost of the screen suite

**The screen suite is the most expensive thing the method runs**: in a real project, hours. Per card it is run
like this, and no more:
- while implementing, the unit tests and **only this card's scenarios**, bounded;
- the whole suite **once**, over the final code, by `verify.mjs`, which wraps it in `.claude/tools/once.mjs`: it
  does not repeat it if it already passed over the same code —so `/close` reuses what `/validate` just ran—;
- if the whole suite takes longer than a card allows, S5 applies: the area now and the full sweep before merging.

## Items of Pause 2 and Pause 4 that apply in a case

- [ ] **T7** *(a rule decided in this card appears on more than one screen)* Each rule decided in this card gives the same answer on **all** the screens where it appears.
- [ ] **T8** *(the card seeds data)* The seeded data: the fields of a record correspond to each other, and the dates follow the causal chain.
- [ ] G1 *(which chapters of the matrix)* Each card answers again only the chapters its diff touches —input: V1 and V2; screens: V3; new routes: V4; files coming in or going out: V5; users and sessions: V6 to V10; personal data: V14; configuration and headers: V13— and leaves the rest as it was. It is the floor, and it is the matrix handed to the client who asks for it.
- [ ] **G7** *(the card declares a security hole)* A declared security hole —no authentication, no encryption— is also where whoever starts the app sees it, and **startup fails until someone chooses** if the risk depends on how it is launched.

## Pause 5 · Accessibility — if the diff touches a screen

- [ ] **A7** The **conformance report** —WCAG 2.2 AA criterion by criterion, with the four states, in VPAT 2.5 international edition format—. What needs a screen reader stays `could not run` until step 9.

## Pause 7 · The next change — the items about enumerations

Read when the diff adds or changes an enumeration (a status, a type, a role, a stage); M1, M7 and M8 are in `/validate`.

- [ ] **M2** What the interface puts on top of each member of an enumeration comes from its **position**, not from its name.
- [ ] **M3** Every table indexed by an enumeration is typed by that enumeration, if the language allows it.
- [ ] **M4** The data that name a member of the enumeration are generated **by traversing it**, not enumerating them by hand.
- [ ] **M5** An `@extensible` test for each enumeration the business is going to extend.
- [ ] **M6** The interface **uses** the domain's rules; it does not copy them.

## Pause 8 · The evidence items that `required.mjs` asks for

Read when `required.mjs` or the close names the session record, the README or what the validations left in the repo; F1, F2 and F6 are in `/validate`.

- [ ] **F3** The session is recorded next to the card: model or models, cost, and where the complete record is.
- [ ] **F4** What the validations generated —coverage, captures, probes, logs— does not stay in the repo: it goes to `.gitignore` or is deleted; `git status --porcelain` shows nothing that is not part of the product. Nothing you opened is left running, and **nothing the close depends on was left in the background**.
- [ ] **F5** **The README says what this card decided**, in its decisions section: each assumption that changes what whoever uses or operates the product sees or does and **each behavior the product adds without the card asking for it**: a log, a block, a limit. Under “Known issues”, **each `OUT` of high or medium severity**: whoever receives the product has to know the record page has an XSS even if this card did not touch it. `specs/` is for whoever follows the process; the README, for whoever receives the product.

## Classifying a finding

Read when the list of actions is not empty.

**A finding reopens the card only if it comes with a failing proof** —a test or a command that
shows the error—, or if it contradicts a criterion of the card or an edge of the plan. One that
cannot be shown failing is an **observation**: it goes to the close and does not trigger another
lap.

**A fix does not add functionality, and a finding about what the card did not create is not an
action.** New code the card did not ask for —another environment, a CSRF token on a form it did not
build—, a defect that already existed and a new capability are scope: they go to `OUT` (with
severity; H or M also under README “Known issues”) or to `AMB-NN`, never to `actions.md`:
`required.mjs` flags an action that names a file outside the File map. Only a defect in what the
card created or changed is an action, and a G security defect it introduced always is.

**Each finding is classified before fixing it, and that decides whether there is another lap:**
- **Changes behavior** —a bug, a failing criterion, a security hole—: it is fixed with a test that
  proves it. **The test is the verification**, not another whole review.
- **Does not change behavior** —a name, a duplication, a style—: it is fixed and not reviewed
  again.
- A G or M action is confirmed by its test and `verify.mjs`, not by a second lap of the inspector, which runs once per close.
  **The same review does not run more than twice per card** —the `reviewer` on the scenarios in red, once, apart from the verdict one—: `.claude/hooks/review-cap.mjs` stops it, and what it would have found is recorded as a finding and goes to the PR.

## Security findings

- [ ] **G5** For each security finding of this card, **the same pattern searched for in the rest of the code**.
- [ ] **G6** A test for each thing that broke here. A fix without a test comes back.

## The edge of F2

The diff has no changes outside the plan's `## File map` that are not one of the `OUT`s that were blocking the card; `required.mjs` checks it.
