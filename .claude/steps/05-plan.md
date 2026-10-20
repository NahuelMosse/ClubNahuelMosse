# Step 5 · The plan

## At a glance

Write `specs/<feature>/plan.md` from `.claude/templates/plan.md` after reading the answers one last time
(the unanswered expire into `ASM-NN`). It has: `## Time plan` (with `cap:`), `## Verification` (with a `stable:` line when the card adds browser scenarios (the card’s scenarios 3 times, T8)), `## File map`
(tests included, in groups, with `rule`, `hot-path` or `presentation` marks), `## Assumptions`, `## Perimeter`,
`## Bar` (every criterion by ID, from `node .claude/tools/bar.mjs`, read whole, in one call), `## Edges`, `## Changes to existing
behavior` and, with a screen, `## Visual brief` (10 lines or fewer, no design template read by you). It is committed before the code, and it is not submitted for approval.

**Closes with:** the plan names the snapshot's scenarios and nothing that is not in `## Scenarios`, and it is
committed. **Then:** `node .claude/tools/bar.mjs --route` says who does steps 6 to 9: the main thread by default; the
`conductor` only if the File map names 15 or more production files (or `context-cap.mjs` warned at 230k tokens), by
`specs/<card>/handoff.md` from `.claude/templates/handoff.md`, committed, and the conductor launched in the foreground with its path.

Most broken:
- A bar that skips a criterion, or an area not collapsed to one line with its range.
- No decision on what the implementer would have to invent: where a rule lives, what is derived, who knows whom.
- A time plan without `cap:`; cutting scope to fit is allowed, cutting a check of the bar is not.
- An interface group of more than about 8 files that is not split by screen.
- A `- <Doc>: unchanged — <why>` line missing for a doc the diff could ask for (README first).

Read the rest only when the card changes stored data, exposes a new interface or needs research (`/speckit-plan`), has a new screen (`## Visual brief`), or its File map names 15 or more production files (`handoff.md`).

## Full rules

**You write the plan, in `specs/<feature>/plan.md`, with the sections below.** `/speckit-plan`
and `/speckit-tasks` are invoked only if the card changes stored data, exposes a new interface or
needs research: there they add `research.md`, `data-model.md` and `contracts/`. **Never
`/speckit-specify`**: it rewrites the requirement and deletes the ambiguity record. The spec is
the card, already frozen. A card that is only text, layout, style or an asset takes the fast lane:
`.claude/steps/fast-lane.md`.

**First, the answers again, the last time**: read the card's comments over the MCP and record what was
answered since the tests were frozen (`.claude/steps/02-ambiguities.md`). What is still unanswered
expires here as `<ID>-AMB-NN · <date> · expired → <ID>-ASM-NN`. The plan is not submitted for
approval: it is committed and the card goes on.

If a requirement of this card contradicts a frozen test of another card, the plan names it under
`## Changes to existing behavior` and step 6 records the `<ID>-RFZ-NN` event (`steps/06-implement.md`).

Start from `.claude/templates/plan.md`: it has the headings and line formats the hook asks for. It is the model;
the plan of another card is not read.
The `require-bar.mjs` hook does not let production code be written while `## Bar`, `## Edges` or
`## Changes to existing behavior` is missing.

## The sections

- `## Time plan` — how the time will be used, decided **before** writing code. See below.
- `## Verification` — **the commands for the mechanical part**, in a code block, one per line as
  `name: command`, taken from `.claude/stacks/<stack>.md`: the suite, the linter for what the
  card touches, one `mutate <file>: node --test <that file's unit tests>` line for each file **the grade asks to mutate** —production: every production file but the `presentation` ones; mvp: only the domain, the files under `domain/` or marked `rule` in the map; poc: none; the head of `bar.mjs` says it— and the attacks and axe if there are routes or screens; **a `stable:` line when the card adds browser scenarios** —`npx playwright test --grep "@<ID>" --repeat-each=3`, the card's scenarios 3 times (T8)—, which `required.mjs` asks for and asks to have passed; `cycles:`, `contract:`, `docs:`,
  `budget:`, `vitals:` and `load:` when the card needs them (`p95`, `budget`, `vitals` and `load`
  run alone, at the end). The lines invoke the repo's `verify:*` scripts, which the pipeline invokes
  too. `verify.mjs` runs them all in parallel, prints each start and end, and kills a line past its limit
(`name [timeout 30 min]: command` per line; else the greater of `VERIFY_TIMEOUT_MIN`, 20 min by default, and 4 times the last measured run of that command) as `could not run: timeout`. A `mutate` line runs against the unit tests of its file, never a suite that starts the app: a test that reaches the whole app makes the record's key the whole repo's, so a round that did not touch the file repeats the mutation, and `mutate.mjs` adds `--test-force-exit` to the `node --test` it runs. What is done comes from what the card touches,
  not from a list of steps.
- `## File map` — the paths that will be touched, **tests included**, and for each one what
  responsibility it has and which structure decisions are already made. A domain file with rules or
  calculations says `rule · test: <path>`: its test is committed first (T13); a hot path says
  `hot-path`, and the plan then has a `load:` line (O22); a view file without logic says
  `presentation`. If the plan adds an infrastructure component, the ADR, `system-design.md` and
  `infra-cost.md` are in the map; the price search goes to a `scout` with web, the decision stays
  in the main thread. **An interface group of more than about 8 files is split by screen** into groups of
  their own: an `implementer` that reaches 300k tokens of context is stopped by `context-cap.mjs`
  (`steps/06-implement.md`).
- `## Assumptions` — the `<ID>-ASM-NN` of step 3, with their tag and whether they work with any
  answer. A non-functional requirement the card gives no number for takes the default of
  `.claude/reference/performance.md` as an `ASM-NN` (R9, O10, O15).
- `## Perimeter` — with what auth, what mocks and what was left out.
- `## Bar` — **every criterion of `.claude/reference/criteria.md`, by ID**: how it is met in
  this card, or `not applicable` and why. **An entire area that does not apply goes on one line
  with its range**: `I1–I32 · not applicable · the card has no screen`. Criteria that are lists
  are unfolded: S15 is the ASVS requirements of the chapters the diff touches; I1 to I12, the
  WCAG criteria the screen brings into play. **The list comes
  from `node .claude/tools/bar.mjs`**, one line per criterion; the complete row of the ones that
  apply, from `node .claude/tools/bar.mjs <ID>…`. `criteria.md` is not read whole: it would be
  re-read on every request of the card. Under a grade below production the same output lists the
  blocks left out as `<block> · off by grade: <grade> — <reason>`: the bar copies each line, and none of
  those criteria is listed or asked for.
- `## Edges` — the edge cases that will be handled, walking the catalog below, one line per
  category: applies and how it is covered, or does not apply and why. Each with its test, chosen
  by a named technique (the matrix of `.claude/reference/testing.md`).
- `## Changes to existing behavior` — what the card adds, modifies or removes of behavior that
  already existed, one line per change, and what stays the same. `nothing: everything is new` if
  so. **One line is always
  the README**: the sentences the change makes false, or `- README: unchanged — <why>`;
  `required.mjs` asks for it at the close. The same line, `- <Doc>: unchanged — <why>`, settles
  `ASVS`, `Docs`, `API contract`, `System design`, `Infra cost`, `ADR`, `Notices`, `Observability`
  and `CI` when the diff would otherwise ask for them.
- `## Visual brief` — **only if the card touches a screen** (module ui, `steps/m-ui.md`): 10 lines or fewer; the implementer reads the design templates.

**Each active module, its part:** `## Step 5` of `steps/m-<module>.md`, for the modules in
that are on (`node .claude/tools/kit.mjs status`). **A module that is off is not turned on or off to close sooner**: if
the card brings its signal, propose `node .claude/tools/kit.mjs on <module>`; only a person, between
cards, turns one off, with its reason.

**Which reference to read.** The plan names the rule IDs that apply and reads only the sections of the
reference it touches (`Read` with the line range of the heading):

| The card touches | Reference in `.claude/reference/` |
|---|---|
| stored data, infrastructure, the pipeline, a documentation site, a language, a screen, an HTTP route's contract | the reference its module names in `steps/m-<module>.md`, if the module is on |
| an endpoint or an integration | `errors.md`, `security.md` |
| a new dependency, a version, a license | `dependencies.md` |
| a hot path or a volume requirement | `performance.md` |
| structure, a pattern, an abstraction | `architecture.md`, `code-patterns.md` |
| a test | `testing.md` |

**Content-only card.** A card that changes the text or the data a page shows, without new logic,
verifies in proportion too: its scenarios read the data from **the same source the page renders
from** —never literals copied from the card—, the captures and the pairwise judge of step 9 look
at the result, presentation files without logic are not mutated, and V5–V7 of the bar are answered
in one line each.

## The time plan

A card **aims at five times** what an agent without the method would take and **never goes past
ten**; below `production` the multiples are smaller (`poc` 3× and 5×, `mvp` 4× and 8×, `levels` of
`modules.json`) and `require-bar.mjs` blocks a cap above them when the line says `without method: a–b–c min`.
**Time is not won by rushing at the end, which worsens the result: it is won by planning what waits
for what.**

The section has five lines:

1. **Size and risk.** The size comes from the map: how many production files, how many acceptance
   criteria, whether there is a new route, screen or stored data. The risk is high if it touches
   money, personal data, permissions, security or something irreversible. Size sets how much
   process runs; risk, how much it is worth paying for a defect.
2. **How long it would take without the method**, at three points —optimistic, likely,
   pessimistic— and looking first at similar cards, not only this one: fixing a field on an
   existing screen, 2 to 10 min; an export with its button, 2 to 5 min; a new screen that saves
   data, 10 to 20 min; an entire site, hours. **The goal is five times the likely and the cap,
   ten**: `without method: 2–3–6 min · goal: 15 min · cap: 30 min`.
3. **The critical path**: the chain of what depends on what came before —scenarios in red, code,
   verification, correction—. What is not in that chain runs **on the side and from the
   beginning**: installs and scaffolding start in the background in step 1, while the ten
   questions are answered; the mechanical verification runs in parallel inside `verify.mjs`.
4. **The split**, in minutes, by phase, built against the goal: plan, code, verification and
   correction. **Correction cannot be the longest phase**: if it is planned to be, the code is
   being written for someone else to fix. It is avoided by verifying while writing —`verify.mjs`
   after each group of files from the map, which only repeats what changed—, not in one batch at
   the end.
5. **What is cut if the plan does not fit**: scope, never quality. If the split does not fit
   within the cap, before starting the card is split or it is asked which part of the scope can
   wait, as `<ID>-AMB-NN`. No check of the bar is removed to make it fit.

What runs alone at the end costs minutes: R4, R10, Q9 and R6 take 1 to 5 minutes each, Testcontainers
adds 10 to 30 seconds per suite, and the price search of an infrastructure card, 5 to 10 minutes with a
`scout`.

## The edges catalog

| Category | The question |
|---|---|
| **Defense against legitimate data** | each defense against hostile data —escaping, neutralizing formulas, validating format— was it tested with a legitimate datum that resembles it? A phone `+54 …`, a name with an apostrophe, a number with leading zeros |
| **State after the action** | after saving, canceling or downloading, does the screen come back as it was? The search, the filter, the focus, the position |
| **Honest notices** | does a result message appear only if the action happened, or can it be produced with a link? |
| **What does not exist** | an id, a file or a route that does not exist: does it give 404 on the new screens too? |
| **Writes** | are they atomic? What happens with two at once? Do they block the server? |
| **Origin of the request** | is the same origin required and not just the same site? `.claude/tools/attack.mjs` tests it |
| **What travels to another program** | was it tested in that program —Excel, another service— with hostile data? |
| **Restart** | does what the user did survive a server restart? |
| **What no test notices** | in the new lines, what change would pass without a test failing? A response code, a limit, an error branch. Mutation measures it |

Visual assumptions are resolved with **“cheapest to undo” = more content, not more
conventional**: one zone, one component, one set of tokens.

**If the plan brings a design decision** —a new service, an external integration, a change of
storage, a queue or a cache—, invoke `clean-architecture` before writing code. A new file with a
pure function is not a design decision. **A card that changes the architecture —a new module,
process, store or external dependency, or a change of boundary— also writes the ADR**
(`.claude/templates/adr.md`, criterion D14) and updates `system-design.md`; any other card declares
`- ADR: unchanged — <why>` and `- System design: unchanged — <why>`.

→ **Validate:** the plan mentions the snapshot's scenarios and says nothing that is not in
`## Scenarios`. And it is committed before the code, with the scenarios in red if they go
together.

## Closing the plan: who does steps 6 to 9

With the plan committed and the scenarios frozen, `node .claude/tools/bar.mjs --route` counts the production files
of the File map (`routeOf`, `tools/card.mjs`). **The main thread does steps 6 to 9 itself**, reading the documents
of each as it reaches it, unless that count is **15 or more**, or `context-cap.mjs` warned the main thread at 230k
tokens: then it hands over. A card of 12 or fewer production files has a single `implementer` for every group, in order.

To hand over, it writes `specs/<card>/handoff.md` from `.claude/templates/handoff.md` —the groups in the plan's
order, the `RFZ` and open `ASM`, the `app:` and `seed:` lines, what already ran, and any decision it took that is
written nowhere else—, commits it, and launches the `conductor` **in the foreground** (no `run_in_background`) with
that path as its whole prompt. Its report is the result. If the call comes back as running in the background, the
main thread waits with `node .claude/tools/wait.mjs --agent <agentId>` or its notification, never by looking for
`closing.md`, which exists before the conductor has returned. It **does not read the documents of steps 6 to 9**: the
conductor does, and what they would add here would be re-read on every request until the end.

On return it reads `closing.md` and `actions.md`, takes any decision the report asks for, and publishes
(`.claude/commands/close.md`, «Publishing»; `.claude/AUTONOMY.md`). A conductor stopped by `context-cap.mjs` is
replaced by a fresh one with the same `handoff.md` and its `handoff-conductor.md`. What decides —the bar, what a
red means, the screen's verdict, what the PR says— is the main thread's or the conductor's, never a `sonnet`'s.

Why each rule is there: `.claude/reference/why-plan.md`.
