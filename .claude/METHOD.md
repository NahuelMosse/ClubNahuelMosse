# SDD method

**The Jira card is the specification. Nothing is assumed in silence: what is assumed is declared, numbered (`<ID>-ASM-NN`) and tied to a test.**
The kit and the code are in English unless CLAUDE.md declares `Code language:`; the rest speaks the team's.
## The flow

1. **`/card <ID>`.** Before `card.md`, one batch of at most 3 parallel calls, ~10k tokens (`git ls-files`, `Grep`, the files the card names); no test or whole file. Bring the whole requirement: Jira over MCP (description, comments, attachments, links; or the `archivist`),
   or the text you were given. If the MCP does not answer, stop. Write `specs/<ID>-<slug>/card.md` with **one `Write`**
   from `.claude/templates/card.md`:
   - header: `status: proposed`, `cap: <N> min`, `sources:`, `not_read:`;
   - `## Specs`: every sentence of the card as `S<n> · "<verbatim quote>"`; an assumption as `<ID>-ASM-NN · <reading> · S<n>`;
   - `## Tasks`: `T<n> · S<n>,… · <files (layer)> · tests: <file> "<title @<ID>-S<n>>"`; a file carries `(presentation|rule|data)`: `rule` does no I/O, SQL lives only in `data`; every `S#` and `ASM` has its planned test; each production task gets an indented `reuses:`/`new:` line, a new pattern a `why-layer:`; each file sits in its slice's layer folder;
   - `## Gate`: one command per line (`suite:`, `lint:`, `mutate <file>: <suite>`, `app:`), and the plan's own: a `probe <state>:` for each state `## Specs` names, `attacks:` with the card's limits, `migrate-upgrade:` if it touches data;
   - `## Log`: `L1` is the requirement, verbatim and whole. L1 never changes; the Log only grows. `Grep` the `@<ID>-S` tags of earlier cards in the files the Tasks touch: each frozen test the card contradicts is declared now as `replaces:`.
   - `## Look` (visual lens): `ref:` (the card, the repo's design system or `reference/design-refs.md`, profile web; never «the simplest»; an `ASM` with the reference of level), `behavior:` per moment, `tokens:`, `copy:`;

   - `## Changes to existing behavior`: a route, screen or file of main the card changes (`none` if it only adds).

   Before `## Specs` closes, walk the questions of the card's lenses in `.claude/reference/lenses.md`: what the card does not answer is an AMB or an ASM with its test.
   Write the folder name to `specs/.current`, switch to branch `<ID>-<slug>`, commit `card.md`.
   **Ambiguities:** what the card does not say (empty case, duplicates, validation, limits, permissions, states, error, order,
   concurrency, trail) is `<ID>-AMB-NN` in `ambiguities.md` (append-only; `publish` reads it). With Jira, all of them go in **one** comment, posted without asking approval,
   each with the option assumed if nobody answers; the unanswered become ASM lines of `## Specs` (cheapest reading to undo, with its test). Never a second round. Without Jira: straight to ASM.
2. **`node .claude/tools/risk.mjs specs/<card>`** checks the plan, then classifies with code and freezes `risk.json`: `size` (small | large), `review`
   (low | medium | high) and the `lenses` (visual, contract, integrity, interpretation, security). A gap in the plan (an `S#` or `ASM` with no test, a file with no layer, a state with no `probe`, no `## Look` under visual, no `attacks:` under contract, no migration line under integrity) is listed and nothing is written: complete the card, rerun. You do not reclassify.
   **Plan judge** (`high` only; `low` and `medium` have no judge, the gate is the review): a `judge` with a prompt starting `PLAN` reads only `card.md` and writes `judge.md`, its ACT marked `plan`. Close each in the card before RED: a new `ASM-NN` with its planned test, a Gate line or `declared · <why>`; the line of `judge.md` says `closed · <ASM-NN, T<n> or Gate line>`; rerun `risk.mjs`.
3. **Build.**
   - **small:** you do it inline, no subagents. RED first: the planned tests, tag `@<ID>-S<n>` (an assumption: `@<ID>-ASM-NN`) in the title,
     failing for the right reason, **committed before any code**; then the code; then the gate.
   - **large:** one `builder` per group of `## Tasks`, prompted with only the path of `card.md`, its task IDs and `S#`, and the gate command. Launch it in the
     background; its notification wakes you (unattended or a subagent: `wait.mjs --agent <id>`).
   - Visual lens: with the tests green, one `designer` does 2-3 capture rounds against `ref/` (`rondas.md`), or the gate fails.
   - An `S#` over a set («un campo», «cada», «todos») gets one planned test per member the card names.
   - Validate what comes from outside on the way in; a missing key of a closed enumeration is an error, not a default. The scope is the
     card's: an unasked control, endpoint or header is a Log line `OUT · <what>`, not built.
4. **Gate.** `node .claude/tools/verify.mjs` runs each line of `## Gate` once, checks every `S#` has a test, and
   prints what fails. What a formatter or generator writes runs before the gate and is committed: a line that changes versioned files fails. Fix and rerun until green, or two rounds without progress: then log it and stop; the close lists it in `## Could not run`.
5. **`/close`.** `node .claude/tools/close.mjs` runs nine checks and writes `closing.md` (`## Passed`, `## Failed`, `## Could not run`,
   `## Judge`, `## Assumptions`, `Cost:`). Then it publishes branch, PR, CI and card comment, and merges once CI passed with nothing for a person; never main, `--force`, `--admin`.

## The invariants

- **The requirement is frozen and verbatim,** also when it arrived as text. Never code from a summary of it.
- **Never resolve an ambiguity on your own.** It is an AMB, asked once, and if unanswered an ASM tied to a test. *Silently filling a gap is the worst failure.*
- **Tagged tests are frozen once committed.** A wrong one is replaced, never edited: write the fixed test in a new file with the same tag and add to the Log `- L<n> · <date> · replaces: <file> "<test>" · <why wrong> · by: <file> "<test>"`; the gate then says `passed with replaced` and the close sends it to «Needs a person». A new behavior is a new test.
- **Three states: passed · failed · could not run.** What did not run is never "passed". A check that stops you is not turned off. An uncorrected finding stops the close.
- **Nothing waits for a person.** A person's call goes in `## Needs a person`; it is not yours (`.claude/AUTONOMY.md`).
- **Grade** (`poc`, `mvp`, `production`): how much of the bar the repo asks (`kit.mjs status`). **Modules** add lenses and gate lines, not steps. The method is the base; a **profile** (`web`, `backend`) brings the screen or API instruments.

## Cost rules

- **One `Write` per file, not ten `Edit`s.** Never `sed -i` or `node -e` to change a file: the guards do not see them.
- **Nothing over ~30 s runs in the foreground:** background, log, `Grep`. A `Monitor` runs `node .claude/tools/wait.mjs <log> --monitor --max 1790`
  (ends on `<tool>: exit <N>`); the turn ends; unattended or in a subagent, `wait.mjs`.
- **A subagent only from the table below,** never `general-purpose`; what decides is never a Sonnet's.
- **Read in depth only what an `S#` touches;** the rest by `Grep`. `bar.mjs <IDs>` prints the criteria rows you need. A tool's usage: `node .claude/tools/help.mjs <tool>`; never read a kit tool's code.
- **Verify by what you touched:** `node .claude/tools/affected.mjs <files>` lists the tests that import them; run those. Whole suites are the gate's. `node --test` always carries `--test-force-exit`.
- **Context caps:** `context-cap` warns builder, grunt and designer at 90k, stops at 120k: commit, `specs/<card>/handoff.md`, a fresh one. The main thread compacts at 200k.

## Who does what

| Task | Agent |
|---|---|
| Builds a group of tasks (RED, code, gate) of a large card | `builder` |
| Capture rounds of a `(presentation)` screen against its `ref/`, after the builder | `designer` |
| Critiques the look (`visual`, `production`); re-checks its blockers once | `design-critic` (Opus) |
| Judges the plan at high (`PLAN`, 12 turns) against the lenses of `risk.json`; writes `judge.md` | `judge` (Opus) |
| Fetches the requirement from Jira and freezes it | `archivist` |
| Sweeps more than two files | `scout` |
| Runs tests, builds, installs, or reads a long log | `runner` · `executor` |
| Applies a decided change in several places | `grunt` |
| Order and risks of something big · a hard problem | `planner` · `oracle` |

## What does not depend on your good will

Hooks block, even when they fail: `guard` (L1 and the Log of `card.md`, `risk.json`, committed tagged tests, `kit.json`), `delegate-code` (production code: `builder`, `grunt`, or you on a small card after RED), `review-cap` (one plan judge, only at high; no code judge, no `FIX`), `require-bar` (cap, Specs, Tasks, Gate before code),
`time-cap` (warns at 70 % of `cap:`, stops at 100 %), `context-cap`, `require-at-close` (mutation, linter of tests, scope, at high `judge.md` with its ACT closed), `publish`. If one stops you, read its message; do not go around it.
What you open, you close.

## Where the scenario tests live

Fixed once, here (`$E2E`); `kit.mjs e2e <path>` changes it.
```
E2E=apps/e2e        # adjust to this repo's real path
```
