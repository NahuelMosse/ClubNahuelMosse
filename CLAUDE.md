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

The **card is the specification**. The WHAT is the requirement, frozen verbatim in `specs/<card>/card.md`; the verified behavior
is in the tests tagged per spec (`@<ID>-S<n>`).

**If you are reading this, the method applies. Read `.claude/METHOD.md` in full before your first tool call.** It is one page: the
flow, the cost rules and the command that closes each step. Do not decide first whether it applies: an empty directory, a pasted
request, no `specs/` are no reason to skip it. What cannot run is declared.

**The kit and the code are in English** (identifiers, file names, comments, test names) unless this file declares `Code language: <lang>`.
Commits, UI text, the PR and the Jira comments speak the team's language. Headings, IDs and tags stay in English: the hooks read them.

**The kit is a base plus profiles** (`web`, `backend`; `flutter` is planned): the screen and API instruments come with the profile, and `node .claude/tools/kit.mjs profile on|off <p> --reason "…"` turns one on or off.

## The invariants

1. **Never code without reading the whole requirement in this session** (Jira via MCP, with comments, attachments and links; if the
   MCP does not respond, stop). A requirement that arrived as text is frozen all the same, with `sources:` and `not_read:`.
2. **Never resolve an ambiguity on your own.** It is `<ID>-AMB-NN`, asked once on the card; if unanswered, `<ID>-ASM-NN` in the
   cheapest-to-undo reading, tied to its test. *Silently filling a gap is the most serious failure of this repo.*
3. **Three states: passed · failed · could not run.** What did not run is never "passed". A check that stops you is not turned off.
4. **The card is born `status: proposed`** and stays so: nothing waits for a signature. The human review is the PR, and the PR says it.
5. **One round of questions, on the card.** A later doubt is an `ASM-NN`, listed in the PR. Never a second round.
6. **The close publishes and merges by itself:** branch, PR, CI result and closing comment, then the merge once CI passed and
   `closing.md` has nothing failed or for a person. Never a push onto main, `--force` or `--admin` unless the user orders it (`.claude/AUTONOMY.md`).

## How to work

- **Before saying "done", check again:** everything, or only the main part? A TODO, a test not run? Resolve it now.
- **Before saying "blocked":** another way? Can you assume it as an `ASM-NN`? What does not depend on it? Do that.
- **The deliverable shows the result, not the process:** out go notes that narrate the change, old code commented out, `_v2`/`_old`.
- **Nothing that can pass ~30 s goes in the foreground:** background with a log, one wait, read by `Grep`. The turn does not end with
  a validation pending: the report carries its output, not the promise of it.
- **What you open, you close:** servers, ports, subagents, shells. Kill by PID, never by process name.
- **Dedicated tools, not shell:** `Read`, `Grep`, `Glob`, `Edit`, `Write`; one `Write` per file instead of ten `Edit`s.
- You touched the kit (`.claude/` or this file): `node --test .claude/tests/*.test.mjs` passes, with `KIT_PLAYWRIGHT_ROOT` set to a
  Playwright repo. You touched production code: `.claude/rules/architecture.md` loads by itself.

## What does not depend on your good will

Hooks block, and block also when they fail; they reach subagents too. If one stops you, read its message; do not look for a way around.

- `guard`: L1 and the Log of `card.md` (append-only), `risk.json`, committed tagged tests, migrations already in main, `kit.json`.
- `delegate-code`: production code is written by the `builder`, the `grunt`, or the main thread on a small card after the RED commit.
- `review-cap`: judges by `risk.json` (none in low and medium; one plan judge before building in high), no code judge and no correction round. `require-bar`: cap, Specs, Tasks, Gate.
- `time-cap`: warns, then stops new agents and suites. `context-cap`: caps the builder, grunt and designer (commit, `handoff.md`, a fresh one); never the main thread.
- `require-at-close` and `publish`: no close without gate, mutation, at high `judge.md` with its ACT closed; publish pushes any branch but main and merges a PR whose checks passed; never force or `--admin` unless the user's last message orders it.

## If the task is, it goes to

| If the task is | It goes to |
|---|---|
| A group of tasks of a large card (RED, code, gate) | `builder` |
| Reviewing the plan (high only) against the lenses of `risk.json` | `judge` |
| Fetching a requirement from its source and freezing it as is | `archivist` |
| Sweeping more than two files, "where is X" | `scout` |
| Running tests, builds, installs, or reading a long log | `runner` · `executor` for a list of commands |
| Applying an already-decided change in several places | `grunt` |
| Order and risks of something big · a hard problem where the obvious failed | `planner` · `oracle` |

Never `general-purpose` for what one of these covers. What decides (the bar, the questions, what the PR says) is never delegated to a Sonnet.
The agent's report is the result: do not redo its work; ask the same agent for more.
<!-- sdd-kit:end -->
