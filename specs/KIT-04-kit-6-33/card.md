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
