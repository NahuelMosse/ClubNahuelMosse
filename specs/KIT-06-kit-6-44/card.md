# KIT-06 · el repo usa el kit 6.44.0

status: proposed
cap: 45 min
sources:
  - "pedido (texto) · mensaje de la sesión que mantiene el kit, anunciado en main de dev-kit D:/projects/SDD-implementation el 2026-11-09, transmitido por la sesión que orquesta las cards"
  - "tag kit-v6.44.0 (4b95e4e8) de dev-kit; origin/main 86a0e36b es el merge de release/kit-6.44.0"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "update this repo's kit from 6.42.0 to 6.44.0" · acceptance: `.claude/kit.json` dice kit 6.44.0
- S2 · "update with `node D:/projects/SDD-implementation/.claude/tools/install.mjs --target . --update`" · acceptance: el kit lo instaló `install.mjs --update` y `.claude/kit.json` registra la fuente de 6.44.0
- KIT-06-ASM-01 · la fuente de la instalación es un clon del tag kit-v6.44.0 (commit 4b95e4e8), no la copia de trabajo de D:/projects/SDD-implementation, que está en la rama fix/method-bullets con cambios sin commitear: así el repo recibe exactamente lo publicado en 6.44.0 · S2

## Tasks

- T1 · S1,S2 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "the installed kit is 6.44.0 @KIT-06-S1"; tests/kit.test.mjs "the kit was installed from the kit-v6.44.0 release @KIT-06-S2"; tests/kit.test.mjs "the install source is the kit-v6.44.0 tag commit @KIT-06-ASM-01"

## Changes to existing behavior

- el método trae 6.43.0 y 6.44.0: «require-at-close lets through a push that first `cd`s into another repo with no card»; «fewer disk writes»; «probe measures `role=status`». Esas novedades las cubre la suite del kit (`.claude/tests`), que se corre aparte con `KIT_PLAYWRIGHT_ROOT`
- tests/kit.test.mjs "el kit instalado es el 6.42.0 @KIT-05-S1" · lo reemplaza "the installed kit is 6.44.0 @KIT-06-S1"

## Gate

```
suite: node --test --test-force-exit tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
refactor-tests: la versión del kit que fija tests/kit.test.mjs pasa de 6.42.0 a 6.44.0; el test de KIT-05 se reescribe en su lugar como el de KIT-06
```

## Log

- L1 · update this repo's kit from 6.42.0 to 6.44.0. The kit maintainer session announced 6.44.0 in main of dev-kit `D:/projects/SDD-implementation` on 2026-11-09. It brings: require-at-close lets through a push that first `cd`s into another repo with no card; fewer disk writes; probe measures `role=status`. Its message said to update with `node D:/projects/SDD-implementation/.claude/tools/install.mjs --target . --update`.
