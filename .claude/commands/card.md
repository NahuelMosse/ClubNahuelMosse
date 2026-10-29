---
description: Freezes the requirement into card.md (specs, tasks, gate, log), classifies it with risk.mjs and asks the one round of questions. Fetches it from Jira over MCP if there is a card; if it arrived as text, freezes that text.
argument-hint: <CARD-ID>
---

Card: `$1`.

1. **Fetch, never remember.** A Jira card: the whole card over the Atlassian MCP, all comments with author and date, all attachments
   (open the ones you can), linked pages. If the MCP does not respond, stop: without the requirement there is no card. A requirement
   that arrived as text is the source all the same: `sources:` says where it came from and `not_read:` what has no channel.
2. **Write `specs/$1-<slug>/card.md` with one `Write`**, from `.claude/templates/card.md`:
   - header: `status: proposed`, `cap: <N> min` (the time the card is worth; `time-cap` warns at 70 % and stops at 100 %),
     `sources:` never empty, `not_read:` present;
   - `## Specs`: every sentence or criterion of the card as `S<n> · "<verbatim quote>" · acceptance: …`; an assumption as
     `$1-ASM-NN · <the cheapest reading to undo> · S<n>`; a `## Look` `ref:` comes from the card, the repo's design system or `.claude/reference/design-refs.md` (profile web), never «the simplest»: it is an `ASM` with the reference of level; `## Look` `tokens:` states mood and genre, and fixes no font family or palette unless the brand or the requester gives them (the designer chooses them after looking at the references);
   - `## Tasks`: `T<n> · S<n>,… · <files (layer)> · tests: <file> "<title @<ID>-S<n>>"`, one line per group of files; every production file carries `(rule)`, `(data)` or `(presentation)`, and every `S#` and `ASM` its planned test;
   - `## Gate`: the commands `verify.mjs` runs, one per line (`suite:`, `lint:`, `mutate <file>: <suite>`, `app:`), plus what the plan already knows: a `probe <state>:` for each state `## Specs` names, `attacks:` with the limits the card says, `migrate-upgrade:` if it touches data;
   - before writing the Log: `Grep` the tags `@<ID>-S` of the earlier cards in the files the Tasks touch; each frozen test the new card contradicts goes in `## Log` as `replaces: <file> "<test>" · <why> · by: <file> "<test>"`;
   - `## Log`: `L1` is the requirement, verbatim and whole. `guard.mjs` freezes L1; the Log only grows.
   Not with a heredoc or `echo >`: `guard-shell` refuses it. Write the folder name, alone on one line, to `specs/.current`, and switch
   to branch `$1-<slug>` if you are on the default branch.
3. **Walk the questions of the lenses.** With the lenses of `risk.json` (or the ones the card will have), go through their questions in `.claude/reference/lenses.md` before `## Specs` closes. What the card answers is a spec; what it does not is an AMB (someone to ask) or an `ASM-NN` in the cheapest reading to undo, with its planned test. A card that changes a route, screen or file of main has `## Changes to existing behavior` (`none` if it does not).
4. **One round of questions.** What the card does not say (the empty case, duplicates, validation, limits, permissions, states, error,
   order, concurrency, what must be stamped now) is `$1-AMB-NN · <date> · open · <question in the business's language, no IDs>` in
   `specs/$1-<slug>/ambiguities.md`. With Jira, all of them go in **one** comment on the card, posted without asking approval, each with
   the option assumed if nobody answers (`.claude/AUTONOMY.md`). Read the answers before the tests; what is unanswered becomes an
   `$1-ASM-NN` line of `## Specs`, in the reading cheapest to undo, with its planned test. Never a second round.
5. `node .claude/tools/risk.mjs specs/$1-<slug>` checks the plan (a test per `S#` and `ASM`, a layer per file, a `probe` per state, `attacks:`, the migration), lists what is missing without writing anything, and when complete writes `risk.json` (size, review, lenses) and freezes it. Complete the card and rerun.
   With review `high` only, launch the `judge` with a prompt starting `PLAN` and the path of `card.md`: it writes `judge.md` with ACT lines marked `plan`. Close each one in the card before RED (a new `ASM-NN` with its planned test, a Gate line, or `declared · <why>`), write `closed · <ASM-NN, T<n> or Gate line>` on its line of `judge.md`, and rerun `risk.mjs`.
6. Commit `card.md` alone. **Closes with:** `git diff --name-only <hash>..HEAD -- specs/$1-<slug>/card.md` (`<hash>`, the commit of `card.md`) lists nothing you
   did not mean; report the specs, the open questions, `not_read:` and the `risk:` line.
