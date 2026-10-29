# KIT-04 · el repo usa el kit 6.33.0

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-29): «hay uno incluso mas nuevo, peditelo y te doy permiso para mergear lo que quieras»"
  - "tag kit-v6.33.0 (26569f7) en D:/projects/SDD-implementation, el más nuevo: lotes 116 a 119"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "hay uno incluso mas nuevo" · acceptance: `.claude/kit.json` dice kit 6.33.0 y cada archivo del kit está como lo dejó `install.mjs --update` desde el tag kit-v6.33.0

## Tasks

- T1 · S1 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "el kit instalado es el 6.33.0 @KIT-04-S1"
  también: .claude/agents/builder.md, .claude/agents/card-runner.md, .claude/agents/design-critic.md, .claude/agents/designer.md, .claude/agents/judge.md, .claude/AUTONOMY.md, .claude/commands/card.md, .claude/commands/close.md, .claude/hooks/commit-why.mjs, .claude/hooks/context-cap.mjs, .claude/hooks/delegate-code.mjs, .claude/hooks/edit-count.mjs, .claude/hooks/guard.mjs, .claude/hooks/guard-shell.mjs, .claude/hooks/require-at-close.mjs, .claude/hooks/require-bar.mjs, .claude/hooks/review-cap.mjs, .claude/hooks/shell-writes.mjs, .claude/hooks/time-cap.mjs, .claude/hooks/turn-budget.mjs, .claude/kit.json, .claude/kit-files.json, .claude/METHOD.md, .claude/modules.json, .claude/profiles/backend.md, .claude/reference/http-defaults.md, .claude/reference/lenses.md, .claude/stacks/node-ts.md, .claude/templates/card.md, .claude/tools/attack.mjs, .claude/tools/close.mjs, .claude/tools/copy-lint.mjs, .claude/tools/design-round.mjs, .claude/tools/gate-checks.mjs, .claude/tools/mutate.mjs, .claude/tools/once.mjs, .claude/tools/plan.mjs, .claude/tools/probe.mjs, .claude/tools/required.mjs, .claude/tools/risk.mjs, .claude/tools/tree-snapshot.mjs, .claude/tools/verify.mjs · los escribió `install.mjs --update` del kit 6.33.0; la configuración y los ayudantes de test de Flutter conservan los plugins del equipo y el formato de `dart format`

## Changes to existing behavior

- el método trae los lotes 116 a 119: contraste, más chequeos en la gate y el plan, captura de referencias y movimiento en una llamada

## Gate

```
suite: node --test tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
```

## Log

- L1 · hay uno incluso mas nuevo, peditelo y te doy permiso para mergear lo que quieras
- L2 · 2026-10-29 · declared · fault-db · la card no toca la base
- L3 · 2026-10-29 · declared · attacks · la card no toca la API
- L4 · 2026-10-29 · replaces: tests/kit.test.mjs "el kit instalado es el 6.29.0 @KIT-03-S1" · el kit pasa a 6.33.0 · by: tests/kit.test.mjs "el kit instalado es el 6.33.0 @KIT-04-S1"
- L5 · 2026-10-29 · kit updated 678bff60daef0b8916c101abfeb14856c6956b83 → 26569f73feb42502ee0ea56bf62ccc84c28a6faa · la card KIT-04 es la actualización del kit
