# Handoff — <ID> · <title>

<!-- Written by the main thread at the end of step 5, as `specs/<card>/handoff.md`, and committed with the plan.
     It points at files and does not copy them. Present tense, a line per field. -->

- card: `specs/<ID>-<slug>/` · snapshot `proposed`
- branch: `<ID>-<slug>` · base commit: `<sha>` · plan commit: `<sha>` · tests-in-red commit: `<sha>`
- grade: `<poc|mvp|production>` · modules: `<on, comma separated, or all>` · lane: `normal`

## Groups, in order (from `plan.md` `## File map`)

1. `<group>` — `<files>` — tests: `<spec files or tags>`
2. `<group>` — `<files>` — tests: `<…>`

## Decided

- RFZ: `<ID>-RFZ-NN` events already recorded, or none
- ASM open: `<ID>-ASM-NN` · `<one line each>`, or none
- app: `<the plan's app: line, or none>` · seed: `<the plan's seed: line, or none>`

## Already ran

- `<command or step>` → `<result: passed · failed · could not run>` · `<log or file>`

## Decisions of the main thread not written elsewhere

- `<a decision, or none>`
