# Handoff REV-03 · arreglos del gate (ronda f)

## Hecho
- Causa de los ERROR en `migrate-upgrade`/`suite`/`scenarios`: la fixture `base_de_migraciones` de `tests/escenarios/test_datos.py` crea la base fija `club_rev03_migraciones_test`; las líneas del gate corren en paralelo y chocan (`UniqueViolation pg_database_datname_index`). El de `test_datos_reemplazos.py` es un ResourceWarning en cascada (conexión del admin sin cerrar tras el fallo).
- Reemplazo: `apps/api/tests/escenarios/test_datos_migraciones.py` (base de nombre único por test, se borra al final) con los tests de S7 y S8; Log L28 y L29 declaran `replaces`. SIN verificar todavía: `/tmp/rev03-f-1.log` (corrida de ese archivo) estaba en curso.

## Hallazgo clave (mutaciones)
Los `mutate` del Gate están rotos: `once.mjs`/`verify.mjs` spawnean con `shell: true` (cmd.exe en Windows) y `node mutate.mjs ... -- cd apps/api && sh ...` se parte en el `&&`: mutate corre el suite `cd apps/api` (siempre verde) => 0/N detectados, todos ALIVE, en los 4 archivos con sobrevivientes. Los tests que los matan YA existen (`tests/unit/test_cola_de_avisos.py` mata dominio/notificaciones.py:92-94).
Arreglo propuesto: que la línea no tenga `&&` de nivel superior. Opción: nuevo `D:/Temp/w/herramientas/pytest-api.sh` (hace `cd apps/api` y llama a pytest-aislado.sh con el resto de los args) y las líneas `mutate ...: sh D:/Temp/w/herramientas/pytest-api.sh uv run --no-sync pytest -q -x <tests>`. Ojo: `cd` relativo, la mutación corre en una copia del repo (cwd = copia).
Luego correr cada una: `node .claude/tools/once.mjs "mutate <archivo>" -- "node .claude/tools/mutate.mjs <archivo> --since <base> --equivalents specs/REV-03-datos/equivalents.md --parallel 2 -- <cmd>"` en background (el comando exacto lo arma `planCommands`, verify.mjs:289-315) y ver los sobrevivientes reales; matar con tests nuevos en archivos no congelados o declarar equivalente en `specs/REV-03-datos/equivalents.md`.

## Falta
1. Confirmar `/tmp/rev03-f-1.log` (test_datos_migraciones.py) y correr `-k migracion` junto a `suite` en paralelo para ver que no chocan.
2. Reescribir líneas `mutate` del Gate (arriba) y añadir `mutate apps/api/app/dominio/reservas.py: ...` con sus tests (`affected.mjs`), y el archivo en la línea T que corresponda (T2 probable). `migrate-upgrade` debería apuntar también a `test_datos_migraciones.py`.
3. Sobrevivientes reales: infraestructura/notificaciones.py:252 y :275, migraciones/env.py:16 (`transaction_per_migration` True->False: test que migre 0007->0008 con CONCURRENTLY, o asserts sobre `invalid` indexes), 0008 líneas 12-13 (`branch_labels/depends_on = None`: equivalente probable).
4. Listar otros fallos de `required:` (`node .claude/tools/required.mjs`), dejar `attacks:` en paz. No correr verify, no pushear.
5. Env: FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702, PATH="/d/projects/flutter/bin:$PATH".
