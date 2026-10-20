# Este repo

El **caso de uso es la card**. Los CU viven en `../CU/` y `../CU-nuevos/`, fuera del repo: cada uno trae
actor, flujo principal, flujos alternativos y reglas de negocio, y se congela con `sources:` apuntando al
archivo. El enunciado del TP —`../Trabajo Práctico_2026.docx.pdf`— manda por encima de cualquier CU.
No hay Jira: las dudas van directo a `<ID>-ASM-NN` y se listan en el cierre.

- No se pushea ni se publica nada salvo pedido expreso: lo que el método publica solo (rama, PR,
  comentario de cierre) queda como *no se pudo correr*, declarado.
- Stack: app Flutter en `apps/mobile`, API FastAPI + SQLAlchemy en `apps/api`, autenticación con Firebase
  (emulador en `firebase.json`), API y base desplegadas en Render (`render.yaml`). Rutas, comandos y equivalencias de Flutter y pytest: `.claude/STACK.md`.
- `apps/mobile/lib/**` y `apps/api/app/**`: `.claude/rules/arquitectura.md` e `interfaz.md`, propias de
  este repo, se cargan solas junto con las del kit.

<!-- sdd-kit:start -->
# How we work in this repo

The **Jira card is the specification**. The WHAT lives in Jira; the HOW, in the plan the
main thread writes (`specs/<card>/plan.md`); the verified behavior, in the tests tagged per card.

## First, before touching anything

**If you are reading this, the method applies. Read `.claude/METHOD.md` in full before your first
tool call.** One page: nine steps, each closing with a command, each naming its annex.

**Do not decide first whether the method applies.** An empty directory, a pasted request, no
`specs/`: none is a reason to skip it. What cannot run is declared.

**The kit is in English; the work speaks the repo's language.** Every card artifact —snapshot
notes, questions, plan prose, test names, comments, commits, UI text, the PR and Jira comments—
goes in the language the repo and its team already use. File names, section headers, IDs and
tags stay in English: the hooks and tools read them.

| When | What to read |
|---|---|
| Any card | `.claude/METHOD.md`; then, at each step, `node .claude/tools/help.mjs step N`: the `## At a glance` of its documents; the rest only if one says so. Steps 6–9 are the main thread's; `bar.mjs --route` says when they go to the `conductor` |
| A module's part of a step (a screen: `ui`) | `steps/m-<mod>.md`; which modules are on: `tools/kit.mjs status` |
| Closing, or checking whether you skipped something | `.claude/MATRIX.md` |
| First card of a repo, or a command that does not run in this stack | `.claude/stacks/` |
| An item of `/validate` seems like too much | `.claude/reference/why-validate.md` |
| The plan's bar, or inspecting | `node .claude/tools/bar.mjs [IDs]`, not `criteria.md` whole |
| Publishing, the one round of questions, what only a person decides | `.claude/AUTONOMY.md` |
| Writing the snapshot | `.claude/templates/card.snapshot.md` |
| Choosing between review skills | `.claude/skills/WHEN.md` |
| The repo's grade | `kit.mjs status`; «Grades» in `reference/criteria.md` |
| You touched production code | `.claude/rules/architecture.md` — **loads by itself** |
| You touched the kit —`.claude/` or this file— | `node --test .claude/tests/*.test.mjs` passes, `KIT_PLAYWRIGHT_ROOT` set to a Playwright repo |

## What does not depend on your good will

- `.claude/hooks/guard.mjs` blocks editing `card.snapshot.md`, `Edit` on `ambiguities.md`
  (append-only), a committed tagged test, a migration already in main, `.claude/kit*.json` (only
  `tools/kit.mjs` writes it), and removing or changing a line of a verification config that
  existed before the card. If it stops you, do not look for a way around: read the message.
- `.claude/hooks/require-at-close.mjs` does not let `/close` start while the mutation of a
  production file or the linter of a test in the diff is missing (`tools/required.mjs`).
- `.claude/hooks/publish.mjs` lets out the card's branch, its PR, one comment of questions and one
  closing comment; not main, force, a draft, a merge, a second round or a closing without `closing.md`.
- `.claude/hooks/delegate-code.mjs` lets only the `implementer` and the `grunt` write production
  code during a card, from the plan and the tests in red.
- `.claude/hooks/no-pending-close.mjs` does not let you end the turn promising to continue when
  something finishes: wait for it or dispatch it to whoever will wait. A subagent's last message
  is its whole report.
- `.claude/hooks/require-bar.mjs` asks the plan's `## Time plan` for `cap: <N> min` or `cap: <N> h`;
  `time-cap.mjs` warns past 70 % and, past 100 %, blocks new agents, suites and mutation: close
  with what there is and declare what did not run.
- The hooks take the card in progress from `specs/.current`, written by `/card`.
- **Hooks that block, block also when they fail**, and they reach subagents too.

## The invariants

1. **Never code without reading the whole requirement in this session** —not from memory, a
   summary or the plan—. With a Jira card: via MCP, with comments, attachments and links; if the
   MCP does not respond, stop: there is no requirement. **A requirement that arrived as text is
   frozen all the same**, with `sources:` and `not_read:`.
2. **Never resolve an ambiguity on your own.** It is `<ID>-AMB-NN` in `ambiguities.md`, asked on
   the card, and if it expires, assumption `<ID>-ASM-NN` in the cheapest-to-undo interpretation,
   tagged in its test. *Silently filling a gap is the most serious failure of this repo.*
3. **Three states: passed · failed · could not run** (`.claude/METHOD.md`); what did not run is
   never “passed”. **Not applicable** only when the requirement says the feature does not exist.
4. **The snapshot is born `status: proposed`** and stays so: nothing waits for a signature. The
   human review is the PR, and the PR says it.
5. **One round of questions, on the card.** Every `AMB-NN` goes in a single Jira comment, posted
   without asking approval; answers are read at fixed points (before the red tests, before the
   plan); the unanswered become `ASM-NN`. Never a second round: a later doubt is an `ASM-NN`,
   listed in the PR. No Jira: straight to `ASM-NN`. *The client sees the card.*
6. **The close publishes by itself, and only that:** the card's branch, a PR ready for review, the
   CI result and the closing comment on Jira, from the output of the validations. Never main,
   `--force` or a merge. A step that cannot run is *could not run*, declared (`.claude/AUTONOMY.md`).

## How to work

- **Before saying “done”, check again**: everything, or only the main part? A TODO, a test not
  run? Resolve it now.
- **Before saying “blocked”**: another way? Can you assume it as `ASM-NN`? What does not depend on
  it? Do that.
- **Doubts go to the queue** —`ambiguities.md`—, not stop the work. Stop only when everything
  pending is blocked by the same doubt.
- **The deliverable shows the result, not the process** —code, tests, plan, Jira comment—. Out:
  notes that narrate the change, old code commented out, `_v2`/`_old`, change sections nobody
  asked for. A comment stays only if it explains what the code does not show.
- **Nothing that can pass ~30 s goes in the foreground of the main thread** —tests, builds,
  installs, servers, `gh pr checks --watch`—: background with a log, read by `Grep` or a subagent.
  **But the turn does not end with a validation pending**: wait for its notification or a subagent
  that waits; the report carries the output, not the promise of it.
- **What you open, you close — and only what you opened.** Servers, ports, containers, subagents,
  shells. **Kill by PID, never by process name**: `taskkill /IM node.exe` takes down other agents.
- **Dedicated tools, not shell**: `Read`, `Grep`, `Glob`, `Edit` to read, search and edit.

## Cost: optimize how the list runs, never what it contains

**No check is removed to save money.** What is paid most is re-reading (`.claude/reference/cost.md`):
**the main thread decides and reviews; it does not write code nor read long output**. Write each
file whole instead of editing it ten times, and group independent calls into one message.

| If the task is | It goes to |
|---|---|
| Sweeping the product's files, “where is X” (kit docs: `help.mjs step N`, never a `scout`) | `scout` |
| Running a list of commands and returning exit codes | `executor` |
| Running tests, builds, linters, installs, or reading any log | `runner` |
| Fetching a requirement from its source and freezing it as is | `archivist` |
| Applying an already-decided change in several places | `grunt` |
| Steps 6 to 9 of a big card (`bar.mjs --route`), from `handoff.md` | `conductor` |
| The code of the plan and the fixes of `actions.md` | `implementer` |
| Order and risks of something big, before the plan | `planner` |
| A second look at the red scenarios (one round), a screen or a route that writes | `reviewer` |
| The judgment criteria and F1 against the running app, in step 8 | `inspector` |
| A hard problem where the obvious already failed | `oracle` |

- **Never `general-purpose` for something one of these covers**: it inherits Opus and your
  context.
- **What decides is never delegated to a `sonnet`**: the ten questions, the bar, what the PR and the
  Jira comment say (main thread); what a red means, the screen's verdict (also the conductor).
- **The agent's report is the result**: do not redo its work; ask the same agent for more.
  Independent subtasks go out in parallel, in one message.
<!-- sdd-kit:end -->
