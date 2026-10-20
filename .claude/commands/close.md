---
description: Runs the card's validations and publishes the branch, the PR and the closing comment using only what they said.
argument-hint: <CARD-ID>
---

Card: `$1`. Run **everything** below and paste the raw output of each command; do not summarize.

## At a glance

`/close $1` runs `node .claude/tools/close.mjs` and pastes its raw output; step 8's output is cited, not repeated (no `inspection.md`: run `/validate $1` first).
It does checks 1 to 12 (hashes from `ambiguities.md`, never from memory), cites the `once` records of 13 to 17, checks 18, adds the
`sessions.md` line of each session record, and writes the mechanical `closing.md` between `close.mjs:begin` and `close.mjs:end`.
**The card's tests are the files with its tag** (`git grep -l "@<ID>-H"`); `E2E=` is a hint (`kit.mjs e2e <path>`).
**15 and 16 cite the `suite` record** when unfiltered and reaching the tagged files. **14** is `could not run` with no type checker
(tsconfig, jsconfig, `typescript`). **17**: `once.mjs captures -- node .claude/tools/app.mjs probe <steps.json>`.
**18**: `specs/<card>/code-review.md`, the saved `/code-review` (its one lap in `.git/sdd-reviews.json`), newer than every production
change no closed `ACT` names, else `failed`; its findings are closed by their `ACT`s, it does not run again (fast lane and poc skip it). Sections:
`## Passed`, `## Failed`, `## Could not run`, `## Refrozen tests`, `## Kit updated during the card`, modules off and grade.
You replace its four `<!-- MAIN: … -->` lines: the heading (passed or not, and which), the ASM (count first, the untested
named), F1 from `inspection.md` (and `review.md`), each OUT with severity. A rerun regenerates only its block, so run it before
writing under it; a `closing.md` it did not write is left alone; `--check` writes nothing.

By hand, if the tool cannot run:
```
git diff --name-only <snapshot-commit>..HEAD -- specs/<feature>/card.snapshot.md  # 1. snapshot intact
grep -rl "@$1-H<NN>-<NN>" $E2E                         # 2. for each snapshot scenario: >= 1 file
grep -rhoE "@$1-H[0-9]+-[0-9]+" $E2E | sort -u         # 3. every tag of this card is in the snapshot
grep -r "@assumption:$1-ASM-" $E2E                     # 4. each ASM: tagged...
grep -A99 "## Uncovered assumptions" specs/<feature>/plan.md # 5. ...or declared uncovered
grep -E "ASM-[0-9]+ ·" specs/<feature>/plan.md | grep -vc "any-answer: "  # 6. 0: each carries `any-answer: yes` or `no — <why>`
git diff --name-only <tests-commit>..HEAD -- $E2E | xargs -r grep -l "@$1-H"  # 8. empty: no tagged test of this card touched
git diff --name-only <card-base>                       # 9. vs `## File map`, both directions; <card-base> = `node .claude/tools/review-range.mjs --base`, not main
grep -cE "· (open|suspect)$" specs/<feature>/actions.md  # 10. 0
grep "· closed$" specs/<feature>/actions.md            # 11. empty: every closed one carries its output
node .claude/tools/required.mjs                        # 12. 0: mutation of each production file and linter of each test in the diff
<suite> · <type checker, strict> · <scenarios by "@$1"> · <whole suite, no captures> · <captures, only if UI>  # 13-17, from the stack profile
ls -l specs/<feature>/code-review.md                   # 18. exists, newer than every production change no closed ACT names; never run again
```

Check 7 (the AMB questions have no jargon or IDs before the `→`) is `grep -E "AMB-[0-9]+ ·.*\?" specs/<feature>/ambiguities.md | sed "s/ → .*//" | grep -cE "ASVS|WCAG|V[0-9]+\.[0-9]+|\b[A-Z][0-9]{1,2}\b|ASM-|OUT-"`, 0.
Checks 13 to 17 use the same `once` names as `/validate`: unchanged code is cited, not rerun; 16 is not 15 again (an old
scenario this card broke only shows in 16); 17 is the strip of captures, skipped and said if no UI or `ui` is off. Fast
lane: 2 and 3 are answered with the before and after captures. Both hashes come from `ambiguities.md` —`$1-AMB-00 · <date> · snapshot · frozen at <hash>`
for 1 and the latest `$1-TESTS` `frozen`/`refrozen` for 8—, never from memory; if one is not recorded, that check is
`could not run`. By eye: no `AMB-NN` has `open` or `asked` as its last event, and each tagged test asserts on a value it created.

**`closing.md`** heads with passed or not (anything in `## Failed` or `## Could not run` is *not passed*, and which), has the
three sections even when empty, and carries what only you know: the scenarios run and their result, the unanswered questions
and late answers, the perimeter, the card link, the snapshot still `proposed` (the PR is the review), the files per change
scenario (M1), the data used, the notices a file asks for («DO NOT TOUCH without telling …»). Before writing, list every server,
port, container and shell you started and bring it down by PID (`node .claude/tools/app.mjs down` for the shared app).
`specs/<feature>/sessions.md`: one line per session —date, models, cost, `record:` of `.validation/sessions.log`—.

The main thread then publishes, in order: `git push -u origin <ID>-<slug>`, `gh pr create --body-file specs/<feature>/closing.md`,
CI in the background (`gh pr checks --watch > .validation/ci.log 2>&1`) and `gh pr comment`, the Jira comment. Never main,
`--force` or a merge. A step that cannot run (no remote, `gh`, Jira, CI) goes to `## Could not run`; nothing is invented.

Most broken:
- Closing over anything in `failed` or `could not run`: the card is not passed, and `closing.md` says which.
- A server, port or shell left alive: each is listed and brought down by PID.
- An invented PR link or CI result when a step could not run: it is `could not run`, declared.
- No remote: `publish: could not run, no remote configured`.

Read the rest only when there is no remote, or the Jira post failed, or `ambiguities.md` has an `RFZ` or `KIT` event to word.

## Details

Step 8 ran if `inspection.md` (and `review.md`, if the card has a screen or a route that writes) exist; `verify.mjs`, run now,
repeats nothing. The validations do not run `/code-review`, the security pass, the accessibility tests nor the coherence of a
rule across screens. The output of `/validate` goes in the comment together with them. Why each rule is there:
`.claude/reference/why-close.md`.

A validation that **failed** is not closed over: it goes to `actions.md` and is corrected. A check is not turned off to close
(`.claude/AUTONOMY.md`). What you cannot bring down, name it: what it is, why it is alive and how it is brought down. Never by
process name: a `taskkill /IM` or a `pkill` takes down other agents', the editor's and the user's.

In `closing.md`, say which scenarios **were run and with what result** —not «were verified»: the gate knows a tagged test ran
green, not that it corresponds to the scenario—. The assumption count is the headline: nine assumptions on a three-field card
is not a footnote. It is written before anything is published: the inspector contrasts it with the validations, and
`publish.mjs` asks for it. `required.mjs` asks for `## Refrozen tests`, `## Kit updated during the card` and the module and
grade lines once `closing.md` exists.

Two reports remain, as evidence a client or an auditor asks for:

| File | What it is |
|---|---|
| `specs/asvs.md` | the sheet from `.claude/templates/asvs-level-1.md` answered row by row; it belongs to the repo, and each card updates only the chapters it touched (G1 of `/validate`). A card with no new inputs, outputs or data adds no rows |
| `specs/<feature>/accessibility.md` | a new screen: the conformance report, WCAG 2.2 AA criterion by criterion, with the structure of a VPAT 2.5 international edition; a changed one: one line for each WCAG criterion the change brings into play |

## Publishing

`publish.mjs` lets out exactly the five steps of the glance (the cycle: `.claude/AUTONOMY.md`):

```
git push -u origin <ID>-<short-slug>                                          # 1. the card's branch, never main, never --force
gh pr create --title "<ID> · <title>" --body-file specs/<feature>/closing.md  # 2. ready for review, against the default branch
gh pr checks --watch > .validation/ci.log 2>&1                                # 3. only if the repo has CI: background with its log
gh pr comment <n> --body-file .validation/ci.md                               # 4. the result of CI, written from the log
addCommentToJiraIssue (the card's key)                                        # 5. the closing comment, with the link to the PR
```

Step 5 is `closing.md` in the business's language with the PR link, once; step 3 is awaited (its notification, or a `runner`
that waits and returns the log). With no remote (`git remote` empty) steps 1 and 2 are not attempted —`publish.mjs` refuses
them— and `## Could not run` gets `publish: could not run, no remote configured (git remote is empty)`. A failed post of 5 is
appended as `<ID>-CLOSE · <date> · failed · <error>`. A `gh pr comment` says what could not run if the PR exists; the card
closes locally all the same, and is not given as passed. Nothing is merged.
