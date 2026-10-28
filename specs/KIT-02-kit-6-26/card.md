# KIT-02 · el repo usa el kit 6.26.0

status: proposed
cap: 30 min
sources:
  - "pedido (texto) · mensaje del usuario en la sesión (2026-10-28): «continua, cuando termines esta card, pasa a actualizar el kit»"
  - "tag kit-v6.26.0 en D:/projects/SDD-implementation (2b77525), incluye 6.25.0: el hilo principal espera trabajo largo con un Monitor, una card se corre y varias se orquestan, el hilo principal compacta a los 200k"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "pasa a actualizar el kit" · acceptance: `.claude/kit.json` dice kit 6.26.0 y cada archivo del kit está como lo dejó `install.mjs --update` desde el tag kit-v6.26.0

## Tasks

- T1 · S1 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "el kit instalado es el 6.26.0 @KIT-02-S1"

## Changes to existing behavior

- el hilo principal espera el trabajo largo con un Monitor y compacta a los 200k de contexto

## Gate

```
suite: node --test tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
```

## Log

- L1 · continua, cuando termines esta card, pasa a actualizar el kit
- L2 · 2026-10-28 · declared · fault-db · la card no toca la base
- L3 · 2026-10-28 · declared · attacks · la card no toca la API
- L4 · 2026-10-28 · replaces: tests/kit.test.mjs "el kit instalado es el 6.24.0 @KIT-01-S1" · el kit pasa a 6.26.0 · by: tests/kit.test.mjs "el kit instalado es el 6.26.0 @KIT-02-S1"
