# KIT-01 · el repo usa el kit 6.24.0

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-27): «actualiza el kit»"
  - "aviso de otra sesión (2026-10-27): kit 6.24.0 (tag kit-v6.24.0 en D:/projects/SDD-implementation), incluye 6.23.0: el usuario puede levantar un rechazo de publish con una orden explícita; capas por carpeta y código en inglés para archivos nuevos"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "actualiza el kit" · acceptance: `.claude/kit.json` dice kit 6.24.0 y cada archivo del kit está como lo dejó `install.mjs --update` desde el tag kit-v6.24.0
- KIT-01-ASM-01 · `.claude/settings.json` conserva los plugins que agregó el equipo (figma): el instalador no lo pisa y la versión nueva sólo difiere en eso · S1
- KIT-01-ASM-02 · no se declara `Code language:` en CLAUDE.md: el código va a inglés (ramas `ingles` e `ingles-api`), así que los archivos nuevos se nombran en inglés · S1

## Tasks

- T1 · S1,KIT-01-ASM-01,KIT-01-ASM-02 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "el kit instalado es el 6.24.0 @KIT-01-S1"; tests/kit.test.mjs "cada archivo del kit está como lo instaló la actualización, salvo settings.json @KIT-01-S1 @assumption:KIT-01-ASM-01"; tests/kit.test.mjs "CLAUDE.md no declara otro idioma para el código @assumption:KIT-01-ASM-02"
  también: .claude/AUTONOMY.md, .claude/METHOD.md, .claude/agents/builder.md, .claude/agents/judge.md, .claude/agents/planner.md, .claude/commands/close.md, .claude/hooks/publish.mjs, .claude/kit-files.json, .claude/kit.json, .claude/modules.json, .claude/profiles/flutter.md, .claude/reference/architecture.md, .claude/reference/lenses.md, .claude/reference/structure.md, .claude/rules/architecture.md, .claude/scheduled_tasks.lock, .claude/stacks/node-ts.md, .claude/templates/card.md, .claude/templates/system-design.md, .claude/tools/code-language.mjs, .claude/tools/gate-checks.mjs, .claude/tools/overdesign.mjs, .claude/tools/plan.mjs, CLAUDE.md · los escribió `install.mjs --update` del kit 6.24.0

## Changes to existing behavior

- el cierre de una card mergea solo cuando CI pasó y closing.md no tiene nada fallido ni para una persona; el usuario puede ordenar un merge o un push que el hook rechaza
- los archivos nuevos van en inglés y en la carpeta de su capa

## Gate

```
suite: node --test tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
```

## Log

- L1 · actualiza el kit
- L2 · 2026-10-27 · declared · fault-db · la card no toca la base
- L3 · 2026-10-27 · declared · attacks · la card no toca la API
- L4 · 2026-10-27 · T1 · `node D:/Temp/w/kitsrc/.claude/tools/install.mjs --target . --update --from D:/Temp/w/kitsrc` (kit-v6.24.0, 1bcd386): 20 archivos reemplazados o agregados, 1 borrado; settings.json quedó como estaba (sólo difería en los plugins del equipo)
- L5 · 2026-10-27 · could not run · tests del kit (`node --test .claude/tests/*.test.mjs`): el kit no instala `.claude/tests/` en el repo; corren en D:/projects/SDD-implementation
