# KIT-03 · el repo usa el kit 6.29.0

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensaje de otra sesión (2026-10-29): kit SDD 6.29.0, tag local kit-v6.29.0 (678bff6) de D:/projects/SDD-implementation"
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-29): «hacelo»"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "hacelo" · acceptance: `.claude/kit.json` dice kit 6.29.0 y cada archivo del kit está como lo dejó `install.mjs --update` desde el tag kit-v6.29.0

## Tasks

- T1 · S1 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "el kit instalado es el 6.29.0 @KIT-03-S1"; tests/kit.test.mjs "cada archivo del kit está como lo instaló la actualización, salvo settings.json y el formato de los ayudantes de Flutter @KIT-03-S1"
  también: .claude/METHOD.md, .claude/agents/builder.md, .claude/agents/card-runner.md, .claude/agents/design-critic.md, .claude/agents/designer.md, .claude/agents/executor.md, .claude/agents/grunt.md, .claude/agents/judge.md, .claude/agents/scout.md, .claude/commands/card.md, .claude/commands/close.md, .claude/hooks/context-cap.mjs, .claude/hooks/delegate-code.mjs, .claude/hooks/edit-count.mjs, .claude/hooks/guard-shell.mjs, .claude/hooks/guard.mjs, .claude/hooks/light-images.mjs, .claude/hooks/no-pending-close.mjs, .claude/hooks/session-record.mjs, .claude/hooks/trim-output.mjs, .claude/kit-files.json, .claude/kit.json, .claude/modules.json, .claude/profiles/backend.md, .claude/reference/color.md, .claude/reference/criteria.md, .claude/reference/cta.md, .claude/reference/design-refs.md, .claude/reference/http-defaults.md, .claude/reference/lenses.md, .claude/reference/testing.md, .claude/rules/architecture.md, .claude/rules/interface.md, .claude/rules/speed.md, .claude/stacks/node-ts.md, .claude/templates/card.md, .claude/tools/attack.mjs, .claude/tools/browser-lock.mjs, .claude/tools/card-view.mjs, .claude/tools/card.mjs, .claude/tools/close.mjs, .claude/tools/copy-lint.mjs, .claude/tools/design-round.mjs, .claude/tools/gate-checks.mjs, .claude/tools/hook-dispatch.mjs, .claude/tools/log.mjs, .claude/tools/migrations.mjs, .claude/tools/motion-audit.mjs, .claude/tools/plan.mjs, .claude/tools/probe.mjs, .claude/tools/risk.mjs, .claude/tools/shell-writes.mjs, .claude/tools/verify.mjs, .claude/tools/wait.mjs · los escribió `install.mjs --update` del kit 6.29.0; la configuración y los ayudantes de test de Flutter conservan los plugins del equipo y el formato de `dart format`

## Changes to existing behavior

- el método trae los cambios de costo y tiempo, las comprobaciones de resultado y la evidencia de banco de los lotes 113 a 115

## Gate

```
suite: node --test tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
```

## Log

- L1 · hacelo
- L2 · 2026-10-29 · declared · fault-db · la card no toca la base
- L3 · 2026-10-29 · declared · attacks · la card no toca la API
- L4 · 2026-10-29 · replaces: tests/kit.test.mjs "el kit instalado es el 6.26.0 @KIT-02-S1" · el kit pasa a 6.29.0 · by: tests/kit.test.mjs "el kit instalado es el 6.29.0 @KIT-03-S1"
- L5 · 2026-10-29 · kit updated 2b775258e85573d025d94f4f2e20b34961a4a3c9 → 678bff60daef0b8916c101abfeb14856c6956b83 · la card KIT-03 es la actualización del kit
- L6 · 2026-10-29 · replaces: tests/kit.test.mjs "cada archivo del kit está como lo instaló la actualización, salvo settings.json @KIT-01-S1 @assumption:KIT-01-ASM-01" · el kit 6.29.0 instala ayudantes de test de Flutter que el repo guarda con `dart format` · by: tests/kit.test.mjs "cada archivo del kit está como lo instaló la actualización, salvo settings.json y el formato de los ayudantes de Flutter @KIT-03-S1"
