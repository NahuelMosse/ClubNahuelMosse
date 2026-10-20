# SDD method — one page

**One rule: the Jira card is the specification. Nothing is assumed in silence; everything that is
assumed is declared, numbered and open to objection.**

**The kit is in English; the work speaks the repo's language.** Write the content of every card
artifact in the language the repo and its team already use; file names, section headers, IDs and
tags stay in English: they are what the hooks and tools read (`CLAUDE.md`, «The language rule»).

Each step closes with a command; the command's output is the evidence. **The detail of each step
is in `.claude/steps/`, and is read on reaching that step**, not before: what is read early is
re-read on every request of the card. `node .claude/tools/help.mjs step N` prints the `## At a glance` of every document that step uses, in one read: that is enough for most cards, and a full document is read only for the case its last glance line names. A kit document is read this way, never delegated to a `scout`. **Nobody reads the code of `verify.mjs`, `close.mjs`, `required.mjs` or `probe.mjs` to know what they ask: their messages say it, and `help.mjs <tool>` the rest.** **Modules** on: `node .claude/tools/kit.mjs status` (no manifest: all on); each adds
its part to a step in `steps/m-<module>.md`. A tool: `node .claude/tools/help.mjs <tool>`.
**Grade** —`poc`, `mvp`, `production` (the default)—: how much of the bar the repo asks, chosen with `kit.mjs grade` and only raised; what it leaves out is one line `off by grade` in the bar (`reference/criteria.md`, «Grades»).

**The card sets the size.** With the method, a task aims at **five times** what an agent without
the method would take, and **never goes past ten**: a one-minute task aims at five, a one-hour
task may take five. Going past ten is a failure of the method, not a slow card. Every criterion is always considered; what scales is how many apply and how much code
has to be verified. **Time is managed from the plan, not by rushing at the end**: the plan
decides from the start what runs on the side, what waits for what, and verifies while writing so
that correction is not the longest phase (`steps/05-plan.md`, “The time plan”).

**Where the files live.** `specs/<ID>-<short-slug>/`: snapshot, ambiguities, plan, actions,
closing. The `ambiguities`, the `closing` and the plan of another card are not read: the model is `templates/`. The scenario tests folder is fixed once, here:
```
E2E=apps/e2e        # adjust to this repo's real path
```

| Step | What | Detail |
|---|---|---|
| **1** | `/card <ID>`: the whole card —description, comments, attachments, links— frozen in `card.snapshot.md`, with `sources:` and `not_read:`. Never edited. The first card of a repo sets up the scaffolding | `node .claude/tools/help.mjs step 1` |
| **2** | The **ten questions** answered in `ambiguities.md`; each gap is an `<ID>-AMB-NN`, and all of them go in **one** comment on the card, once | `node .claude/tools/help.mjs step 2` |
| **3** | The answers are read from the card before the red tests and before the plan; what is still unanswered is an `<ID>-ASM-NN`, the option that works with any answer or the cheapest to undo, tagged in its test or declared uncovered | `node .claude/tools/help.mjs step 3` |
| **4** | Each scenario of the card is a test tagged `@<ID>-H<NN>-<NN>`, **red, before the code** | `node .claude/tools/help.mjs step 4` |
| **5** | `plan.md`: time plan, file map, assumptions, perimeter, bar of every criterion, edges, what changes of what was already there, visual brief if there is a screen. It is committed before the code | `node .claude/tools/help.mjs step 5` |
| **6–9** | **The main thread's by default; the conductor's on a big card.** `node .claude/tools/bar.mjs --route` says which: the plan's File map names 15 or more production files, or `context-cap.mjs` warned the main thread at 230k tokens, and it writes `specs/<card>/handoff.md` (`templates/handoff.md`) and launches the `conductor` in the foreground, which does 6 to 9 and returns with `closing.md` committed; otherwise it does them itself. An `implementer` writes the code against the bar without touching the frozen tests —one for every group with 12 or fewer production files, one per group above that— (**6–7**, `steps/06-implement.md`); then **a single verdict** —`verify.mjs` plus a proportional judgment, every failure to `actions.md` and corrected at once (**8**, `steps/08-verify.md` · `/validate`)—, and a look at the screen if there is one (**9**, module ui, `steps/m-ui-screen.md`), ending with `closing.md` committed | `node .claude/tools/help.mjs step 6` · `help.mjs step 8` · `help.mjs step 9` |
| **close** | The main thread reads `closing.md` and `actions.md`, then publishes (`/close`, «Publishing»): push of the card's branch, a PR ready for review, the CI result on it and the comment on the card; no merge | `node .claude/tools/help.mjs step close` |

**A card cut by a compaction or a crash** is resumed with `node .claude/tools/where.mjs` and
`.claude/steps/00-resume.md`. **Fast lane** (text, layout, style or an asset; presentation only; at
most 30 lines and 3 files): `.claude/steps/fast-lane.md`; a hook takes the card out of it when it
does not fit.

**The three states: passed · failed · could not run.** If a command does not exist, could not be
run, or you did not run it, **do not say it passed** and do not close the card. “Could not run”
is “I don't know”.

**No escape valve.** A check that stops for a reason nobody understands in under a minute is not
turned off: it stops the card, which is reported with what it lacks (`.claude/AUTONOMY.md`).

**Nothing waits for a person.** No approval of the plan, no signature of the snapshot, no «ok,
continue»: the one round of questions goes on the card, the review is the PR, and what a person
alone decides —turning a module off, lowering the grade— is not the agent's to do (`AUTONOMY.md`).

**The card sets the scope.** What the card does not ask —an extra control, `/health` or `/ready`, a search box, a security header the grade does not require— is not built: it is proposed as `<ID>-OUT-NN` in `ambiguities.md`. What the active criteria of the grade ask is not extra.

**An uncorrected finding stops the close.** Running a review, writing the report and closing anyway produces the evidence that something was wrong and files it away.

**Spec-kit skills:** `/speckit-plan` and `/speckit-tasks` only when the card changes stored
data, exposes a new interface or investigates something. `/speckit-specify` is **forbidden**:
it rewrites the requirement. `/speckit-clarify` is not used: step 2 goes against the real card.
Which skill goes at which moment: `.claude/skills/WHEN.md`.
