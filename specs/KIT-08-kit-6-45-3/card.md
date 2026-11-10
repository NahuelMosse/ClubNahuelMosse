# KIT-08 · el repo usa el kit 6.45.3

status: proposed
cap: 90 min
sources:
  - "user, session 2026-11-10"
  - "tag kit-v6.45.3 (2ab9b540, chore(release): kit 6.45.3) de dev-kit, clonado en D:/Temp/w/kitsrc6453"
not_read:
  - "Jira: no hay ticket; el pedido llegó como texto"

## Specs

- S1 · "Actualizar app-tp al kit 6.45.3." · acceptance: `.claude/kit.json` dice kit 6.45.3 y lo instaló `install.mjs --update`
- KIT-08-ASM-01 · la fuente de la instalación es un clon del tag kit-v6.45.3 (commit 2ab9b540), no la copia de trabajo de dev-kit, que puede estar en otra rama con cambios sin commitear: así el repo recibe exactamente lo publicado en 6.45.3 · S1

## Tasks

- T1 · S1 · tests/kit.test.mjs (rule) · tests: tests/kit.test.mjs "the installed kit is 6.45.3 @KIT-08-S1"; tests/kit.test.mjs "the install source is the kit-v6.45.3 tag commit @KIT-08-ASM-01"

## Changes to existing behavior

- el método trae 6.45.2 y 6.45.3: «publish levanta su bloqueo sólo en el hilo principal y por 30 min»; «close.mjs lee sólo campos `closing:` reales»; «un replaces: que conserva las etiquetas y suma otras cuenta como renombre»; «se aceptan commits `KIT-NN: …`»; «la espera de CI cierra con `echo "gh: exit $?"`»; «el pie de closing.md lleva la atribución»; «la espera del módulo worktree»; «`.kit-incoming` va a `.git/info/exclude`». Esas novedades las cubre la suite del kit (`.claude/tests`), que este repo no instala
- tests/kit.test.mjs "the installed kit is 6.45.1 @KIT-07-S1" · lo reemplaza "the installed kit is 6.45.3 @KIT-08-S1"
- tests/kit.test.mjs "the install source is the kit-v6.45.1 tag commit @KIT-07-ASM-01" · lo reemplaza "the install source is the kit-v6.45.3 tag commit @KIT-08-ASM-01"

## Gate

```
suite: node --test --test-force-exit tests/kit.test.mjs
lint: npx -y eslint@9 --no-config-lookup --rule {"no-unused-vars":"error"} tests/kit.test.mjs
no-docs: la card actualiza el kit, que trae su propia documentación
no-visual: no toca pantallas
refactor-tests: la versión del kit que fija tests/kit.test.mjs pasa de 6.45.1 a 6.45.3; los tests de versión y de fuente de KIT-07 se reescriben en su lugar como los de KIT-08
```

## Log

- L1 · Actualizar app-tp al kit 6.45.3.
- L2 · 2026-11-10 · replaces: tests/kit.test.mjs "the installed kit is 6.45.1 @KIT-07-S1" · el kit pasa a 6.45.3 · by: tests/kit.test.mjs "the installed kit is 6.45.3 @KIT-08-S1"
- L3 · 2026-11-10 · replaces: tests/kit.test.mjs "the install source is the kit-v6.45.1 tag commit @KIT-07-ASM-01" · la fuente pasa al tag kit-v6.45.3 · by: tests/kit.test.mjs "the install source is the kit-v6.45.3 tag commit @KIT-08-ASM-01"
- L4 · 2026-11-10 · kit updated b2ab219bf5afa9bda90c3c24f3a3c043372fc1b0 → 2ab9b5405b15b5170e1e6e332814e4d21502c435 · KIT-08 es la actualización del kit a 6.45.3
- L5 · 2026-11-10 · declared · fault-db · la card no toca la base
- L6 · 2026-11-10 · declared · attacks · la card no toca la API
- L7 · 2026-11-10 · kit: la suite propia del kit (.claude/tests) no se instala en este repo; las novedades de 6.45.2 y 6.45.3 no tienen prueba acá más allá de tests/kit.test.mjs
