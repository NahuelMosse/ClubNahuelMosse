# KIT-05 · el repo usa el kit 6.42.0

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-11-08): «hay version nueva del kit, dev-kit en mi gh»"
  - "tag kit-v6.42.0 (a1b87003) de https://github.com/NahuelMosse/dev-kit, el más nuevo; clon local D:/projects/SDD-implementation, origin/main b2d4c535"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "hay version nueva del kit, dev-kit en mi gh" · acceptance: `.claude/kit.json` dice kit 6.42.0 y cada archivo del kit está como lo dejó `install.mjs --update` desde el tag kit-v6.42.0

## Tasks

- T1 · S1 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "el kit instalado es el 6.42.0 @KIT-05-S1"

## Changes to existing behavior

- el método trae las versiones 6.34.0 a 6.42.0: más chequeos de gusto y oficio en el inspector, paletas y hoja de marca en las rondas de diseño, notas de mejora del kit, y cierre y guards que leen transcripts grandes por partes

## Gate

```
suite: node --test tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
```

## Log

- L1 · hay version nueva del kit, dev-kit en mi gh
- L2 · 2026-11-08 · declared · fault-db · la card no toca la base
- L3 · 2026-11-08 · declared · attacks · la card no toca la API
- L4 · 2026-11-08 · replaces: tests/kit.test.mjs "el kit instalado es el 6.33.0 @KIT-04-S1" · el kit pasa a 6.42.0 · by: tests/kit.test.mjs "el kit instalado es el 6.42.0 @KIT-05-S1"
