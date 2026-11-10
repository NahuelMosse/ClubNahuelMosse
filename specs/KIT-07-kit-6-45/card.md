# KIT-07 · el repo usa el kit 6.45.1

status: proposed
cap: 90 min
sources:
  - "pedido (texto) · mensaje de la sesión que mantiene el kit, anunciado en main de dev-kit D:/projects/SDD-implementation el 2026-11-10, transmitido por la sesión que orquesta las cards"
  - "tag kit-v6.45.1 (b2ab219b, chore(release): kit 6.45.1) de dev-kit"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "update this repo's kit from 6.44.1 to 6.45.1" · acceptance: `.claude/kit.json` dice kit 6.45.1
- S2 · "update with `node D:/projects/SDD-implementation/.claude/tools/install.mjs --target . --update [--card-open \"<reason>\"]`" · acceptance: el kit lo instaló `install.mjs --update` y `.claude/kit.json` registra la fuente de la que lo actualizó
- KIT-07-ASM-01 · la fuente de la instalación es un clon del tag kit-v6.45.1 (commit b2ab219b), no la copia de trabajo de D:/projects/SDD-implementation, que puede estar en otra rama con cambios sin commitear: así el repo recibe exactamente lo publicado en 6.45.1 · S1,S2

## Tasks

- T1 · S1,S2 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "the installed kit is 6.45.1 @KIT-07-S1"; tests/kit.test.mjs "the kit records the source the installer updated it from @KIT-06-S2 @KIT-07-S2"; tests/kit.test.mjs "the install source is the kit-v6.45.1 tag commit @KIT-07-ASM-01"

## Changes to existing behavior

- el método trae 6.45.0 y 6.45.1: «the brand sheet passes when the repo already used every colour»; «under refactor-tests, a tag-preserving `replaces:` is a rename and is recorded in Decisions, not in Needs a person»; «`close.mjs` routes `closing: could not run` to Could not run»; «the frozen-names cache»; «the `kit.mjs rule-paths` command»; «publish judges `gh pr` run after a `cd` in that repo». Esas novedades las cubre la suite del kit (`.claude/tests`), que este repo no instala
- tests/kit.test.mjs "the installed kit is 6.44.1 @KIT-06-S1 @KIT-06-S3" · lo reemplaza "the installed kit is 6.45.1 @KIT-07-S1"
- tests/kit.test.mjs "the install source is the kit-v6.44.1 tag commit @KIT-06-ASM-01" · lo reemplaza "the install source is the kit-v6.45.1 tag commit @KIT-07-ASM-01"

## Gate

```
suite: node --test --test-force-exit tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
refactor-tests: la versión del kit que fija tests/kit.test.mjs pasa de 6.44.1 a 6.45.1; los tests de versión y de fuente de KIT-06 se reescriben en su lugar como los de KIT-07
```

## Log

- L1 · update this repo's kit from 6.44.1 to 6.45.1. The kit maintainer session announced 6.45.1 in main of dev-kit `D:/projects/SDD-implementation` on 2026-11-10. It brings: the brand sheet passes when the repo already used every colour (dev-kit PR #14); under refactor-tests, a tag-preserving `replaces:` is a rename and is recorded in Decisions, not in Needs a person; `close.mjs` routes `closing: could not run` to Could not run; the frozen-names cache; the `kit.mjs rule-paths` command; publish judges `gh pr` run after a `cd` in that repo. Its message said to update with `node D:/projects/SDD-implementation/.claude/tools/install.mjs --target . --update [--card-open "<reason>"]`.
