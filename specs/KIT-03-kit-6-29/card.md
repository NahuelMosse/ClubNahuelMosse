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

- T1 · S1 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "el kit instalado es el 6.29.0 @KIT-03-S1"

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
