# Handoff · REV-06 · mutaciones

## Hecho
- Kit 6.5.4 instalado (settings.json local conservado). Commits hasta "REV-06: gate con envoltorios".
- Supresiones: los `type: ignore` de `test_identidad_ingreso.py` y `test_protecciones.py` no tenían tag; se reescribieron con `cast(Any, …)`. `test_sin_supresiones.py` pasa; mypy, ruff limpios.
- Gate: `lint` -> `sh D:/Temp/w/herramientas/lint-api-rev06.sh`, `app-suite` -> `flutter-app-rev06.sh`, mutaciones Dart -> `flutter-mobile.sh <test>`. No usar `sh -c` ni `cd … &&`. `once.mjs lint` sale 0.
- K4 API: jscpd de `apps/api/app` 1,03 % (< 3); los clones declarados L35-L82 son de tests congelados.
- `main.py` agregado a T6 y su línea `mutate` al Gate (required.mjs lo pedía).

## Falta (mutaciones; script D:/Temp/w/herramientas/rev06-mutaciones.sh, logs /tmp/rev06-mut-*.log)
- Python (`infraestructura/*`, `aplicacion/*`, `dominio/*`, `main`, y Dart `registro.dart`): `mutate.mjs --since 64da44a…~1` sale 3 "no operator applies to this file — could not measure" (las líneas cambiadas no tienen operador mutable). Falta declararlo en el Log por archivo (`- L<n> · declared · mutate · <archivo> · ninguna línea cambiada admite un operador`) o revisar si mutate necesita otro `--since` (hay que ver qué base usa `node .claude/tools/required.mjs`: `64da44a189892f31215846c7abd052b7a34d02b4~1`, que tras el rebase puede no ser la base de REV-06; probar con `git merge-base HEAD card/REV-01`).
- `comun/tarjeta_reserva.dart`: 3 vivos, sólo tamaños de ícono (16->17, 18->19, líneas 17, 61, 76): declarar en `specs/REV-06-arquitectura/equivalents.md` (cosmético, sin efecto en el comportamiento) con el formato que imprime mutate.
- `reservas/reservas.dart:110` `==` -> `!=` en `_enElClub` vivo: agregar un test (archivo nuevo, no tocar los congelados) de `Reserva.desdeJson` con fecha ISO inválida (devuelve null) y válida.
- Después `node .claude/tools/required.mjs` (con `grep -v "linter on"`; la lista de linter se cierra con `node .claude/tools/once.mjs lint -- "sh D:/Temp/w/herramientas/lint-api-rev06.sh"`, ya corrido) y cerrar lo que quede. Correr con FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702 y PATH="/d/projects/flutter/bin:$PATH"; nada de verify ni push.
