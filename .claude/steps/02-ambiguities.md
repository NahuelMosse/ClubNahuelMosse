# Steps 2 and 3 · What the card does not say, and what expires unanswered

## At a glance

Answer **all ten questions** in `ambiguities.md`, one line each even when the card says it; every gap is an
`<ID>-AMB-NN`. Every open one goes in **one** comment on the card, once, without asking approval. The answers
are read at two points, before `/scenarios` and before the plan; what is still unanswered then becomes
`<ID>-ASM-NN` in the interpretation that works with any answer or, failing that, the cheapest to undo. Between readings equally cheap to undo, the one that needs no further `ASM` (it opens no new gap: cents, ties, an extra rule). Before choosing, read each reading against every sentence of the card; a sentence the chosen one leaves without effect is named in its event (`→ <ID>-ASM-NN · leaves without effect: «<quote>»`) and in its line of the plan's `## Assumptions`.

The ten, one row each in the `## The ten questions` block that heads `ambiguities.md`, before `## Events`:
**Empty case** (what is seen when there are none) · **Duplicates** (identical by which field) · **Validation** (what is
rejected, by what criterion, with what message) · **Limits** (exact or partial, case, how many at most, **with the boundary
values written**) · **Permissions** (who can and who cannot) · **State** (are there states, **with the transition table**) ·
**Error** (what happens when it fails) · **Order** (in what order they are shown) · **Concurrency** (two at the same time) ·
**Trail** (what has to be stamped now because it cannot be reconstructed later). Each row says `the card says: "<quote>"`,
`the card does not say → <ID>-AMB-NN` or `not applicable: <reason>`; a blank row is this step's failure.

```
| Empty case    | the card does not say → <ID>-AMB-01
| Validation    | the card says: "the CUIT has to be valid"
| State         | not applicable: the client has no states
<ID>-AMB-00 · <date> · snapshot · frozen at <hash>
<ID>-AMB-01 · <date> · open · <the question, in the business's language, no IDs>
<ID>-AMB-01 · <date> · asked · question 1 of the single comment on the card
<ID>-AMB-01 · <date> · resolved · <answer> · <author>, <date>
<ID>-AMB-01 · <date> · expired → <ID>-ASM-01
<ID>-AMB-01 · <date> · no channel · <the question> → <ID>-ASM-01
<ID>-OUT-01 · <date> · high · src/listing.mjs:42 · <defect of another feature> — not touched
<ID>-OUT-02 · <date> · proposal · <what, no file:line> — not asked by the card
```

`ambiguities.md` is created whole with `Write` (the ten questions and the first events); afterwards each event is one
line appended with `>>`, never edited. An assumption is `- <ID>-ASM-NN · <the assumption> · any-answer: yes` (or
`any-answer: no — <why>`) in the plan's `## Assumptions`, tagged `@assumption:<ID>-ASM-NN` in its test or listed in
`## Uncovered assumptions`.

**Closes with:** `grep -cE "^\| *(Empty case|Duplicates|Validation|Error|State|Permissions|Limits|Order|Concurrency|Trail) *\|.+[^ |]" specs/<feature>/ambiguities.md`
gives 10, and no `AMB-NN` ends in `open` or `asked`.

Most broken:
- A second round of questions: a later doubt is an `ASM-NN` listed in the PR, never a new comment.
- Questions with IDs or jargon: they are read by someone who does not know the kit.
- «Not doing it because of scope» is an `ASM-NN`; what the card did not ask is an `OUT`, never built.
- No channel: one `no channel` event per AMB, `→ ASM-NN` at once; nothing is posted.

Read the rest only when the card has no channel to ask on, an answer arrives after the deadline, or an `OUT` has to be withdrawn or classified.

## Why ten, and why Trail

**Reading while looking is not enough:** this step is **a closed list answered in full**, in two pauses of five (what
comes in; what happens after). **Trail is the only one whose cost rises with time.** When it was created, who changed it
and when — it is stamped even if there is no screen yet to show it.

In an epic, dispatch two independent readings and compare them; in a small card, a single reading, and say so. Their
agreeing does **not** prove the card was clear.

## The record

The `OUT`s show up during the card, not in this step: they are defects of **another** feature found while working. They
are recorded so they are not lost, and they are not fixed in this card. An `OUT` is also a **proposal**: what the card did
not ask for —a control, `/health`, a search box, a header the grade does not require— is not built. What the grade's active
criteria require is not extra.

A heredoc that creates `ambiguities.md` is rejected by `guard-shell`. Each ambiguity goes to
`specs/<feature>/ambiguities.md`, one line per event, append-only: `open → asked → resolved | expired`.

**The questions leave once, in a single comment** (invariant 5 of `CLAUDE.md`; the cycle is in
`.claude/AUTONOMY.md`, «The one round of questions»). When the ten are answered, every `open` `AMB-NN`
goes in **one** comment on the card —`addCommentToJiraIssue`, no approval asked—: numbered, each with
its options and the one assumed if nobody answers, saying that the answers are read before the tests
and before the plan. Each gets `asked · question <n> of the single comment`; `publish.mjs` records
`<ID>-ASK` and blocks a second comment of questions.

**The answers are read, not waited for, at two points** —before `/scenarios` and before the plan—, over
the MCP: each becomes `resolved · <answer> · <author>, <date>`. **The deadline is the second reading**:
what has no answer then is `expired → <ID>-ASM-NN`. A later answer, or one that contradicts an
assumption already frozen in a red test, is not applied: it goes to the PR with the cost of undoing the
assumption. After that nothing is asked again: a new doubt is an `ASM-NN` with its test, listed in the PR.

**If there is no channel to ask on** —the requirement arrived as text, there is no MCP, the post
failed twice—, the cycle collapses into one `no channel` event per ambiguity, and the PR says that nobody was asked.
**A record that bloats stops being read.**

**While implementing, every “I'm not doing this because of scope” is an `ASM-NN`.** The moment
of choosing not to leave something is exactly the moment to note it.

## The assumptions

What expires unanswered goes to `## Assumptions` of the plan as `<ID>-ASM-NN`, always the
interpretation that is **cheapest to undo**, tagged in the test that implements it:
`@assumption:<ID>-ASM-NN`. **If there is an option that works with any answer, that is the assumption.** Each line says
it: `any-answer: yes` — or `any-answer: no — <why>`. The marker is the kit's and stays in English
so `/close` can read it; the reason goes in the repo's language.

**Not every assumption has a test to live in, and forcing it is worse.** Each `ASM-NN` goes to
one of two columns:

| | How it ends up | What it means |
|---|---|---|
| **Covered** | `@assumption:<ID>-ASM-NN` in the test that exercises it | it was assumed and verified |
| **Uncovered** | a row in `## Uncovered assumptions` of the plan, with the reason | it was assumed and **nobody tested it** |

→ **Validate:** for each `ASM-NN`, either `grep -r "@assumption:<ID>-ASM-NN" $E2E` returns a
line, or it appears in `## Uncovered assumptions`. **An assumption that is in neither is hidden.**
The uncovered ones go to the closing comment, named one by one.
