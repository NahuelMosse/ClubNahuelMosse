# Plan — <ID> · <title>

<!-- The headings below are the ones require-bar.mjs asks for before production code is written.
     steps/05-plan.md says what goes in each one. -->

## Time plan

1. Size and risk: <production files, criteria, new route/screen/data> · <risk: money, personal data, permissions, security, irreversible, or low>
2. without method: <optimistic>–<likely>–<pessimistic> min · goal: <5× likely> min · cap: <N> min
3. Critical path: <what waits for what> · on the side from the start: <installs, scaffolding>
4. Split: plan <N> · code <N> · verification <N> · correction <N> min
5. Cut if it does not fit: <scope, never a check of the bar>

<!-- The cap is `cap: <N> min` or `cap: <N> h`. Below production, `without method` bounds it:
     poc 3×–5×, mvp 4×–8× the likely time. -->

## Verification

```
suite: <command>
lint: <command>
mutate <file the grade mutates>: <suite that covers it>
app: <command that starts the app, with PORT and DATA_DIR from its environment>
seed: <optional command that loads data once, with APP_URL>
migrate-upgrade: <one command, no | or &: the upgrade from main's last state with seeded data (a script, or node --test --test-name-pattern=<word> <file>); only when the File map has a migration>
```

<!-- One `name: command` per line. A `mutate <file>:` line only for the files the grade asks to mutate
     —`node .claude/tools/bar.mjs` says which: poc none, mvp the domain files (under `domain/` or marked `rule`),
     production every production file but the `presentation` ones—; verify.mjs skips the others as
     `skipped: not required by grade <g>`. `app:` and `seed:` are not checks: `tools/app.mjs` starts the
     one app every judge of step 8 shares (a card with no running product needs neither). p95, budget, vitals and load lines run alone, at the end. -->

## File map

- <path> — <responsibility; `rule · test: <path>` | `hot-path` | `presentation`>

<!-- Tests included. A schema or infrastructure file asks for a `- System design:` line below. -->

## Assumptions

- <ID>-ASM-NN · <tag> · any-answer: <yes|no — <why>>

## Perimeter

<auth, mocks, what was left out>

<!-- The Bar below: paste the skeleton at the end of `node .claude/tools/bar.mjs`, one line per criterion,
     `- <ID> · <how it is met in this card>` or `- <ID> · not applicable · <why>`. A whole area goes on
     one line with its range: `<first ID>–<last ID> · not applicable · <why>`. A module that is off and a
     block the grade leaves out take one line each, copied from bar.mjs: `<module> · off by decision ·
     <reason>`, `<block> · off by grade: <grade> — <reason>`. -->

## Bar

- <ID> · <how it is met>

## Edges

<!-- One line per category of the catalog of steps/05-plan.md. -->

- Defense against legitimate data · <applies and how, or does not apply and why>
- State after the action · <…>
- Honest notices · <…>
- What does not exist · <…>
- Writes · <…>
- Origin of the request · <…>
- What travels to another program · <…>
- Restart · <…>
- What no test notices · <…>

## Changes to existing behavior

- README: unchanged — <why>
- ASVS: unchanged — <why>
- <what the card adds, modifies or removes of what already existed, and what stays the same; `nothing: everything is new`>

<!-- `- <Doc>: unchanged — <why>` also settles Docs, API contract, System design, Infra cost, ADR,
     Notices, Observability and CI when the diff would ask for them. -->

## Visual brief

<!-- Only if the card touches a screen. What the card says disappears or is replaced leaves the DOM in the
     event's task: no exit animation on that node; motion goes on what enters and the neighbors. A line
     here that contradicts the snapshot is a `fails` of the plan. -->
