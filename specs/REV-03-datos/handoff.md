# Handoff — REV-03 · datos

- card: `specs/REV-03-datos/` · snapshot `proposed`
- branch: `card/REV-03`, worktree `D:/Temp/w/rev03` · base commit: `138bc54` · plan commit: `f886ad0` · tests-in-red commit: `f886ad0` (evento en `e492753`)
- grade: `production` · modules: `ui, api, data, infra, observability, security-l2` · lane: `normal`

## Groups, in order (from `plan.md` `## File map`)

1. `migración` — `apps/api/migraciones/versions/0008_indices_y_cola_recuperable.py`, `apps/api/migraciones/env.py` — tests: `@REV-03-H10-01`, `@REV-03-H10-04`, `@REV-03-H13`
2. `historiales por marcador` — `apps/api/app/interfaz/marcador.py`, `apps/api/app/infraestructura/reservas.py`, `apps/api/app/interfaz/reservas.py`, `apps/api/app/aplicacion/reservas.py` — tests: `@REV-03-H10-02`, `@REV-03-H10-03`
3. `cola de avisos` — `apps/api/app/dominio/notificaciones.py`, `apps/api/app/infraestructura/notificaciones.py`, `apps/api/app/aplicacion/notificaciones.py` — tests: `@REV-03-H11`
4. `app` — `apps/mobile/lib/reservas/reservas.dart`, `apps/mobile/lib/reservas/pantalla_mis_reservas.dart`, `apps/mobile/lib/admin/historial_reservas.dart` — tests: `apps/mobile/test/historial_por_tandas_test.dart`

Escenarios de la API: `apps/api/tests/escenarios/test_datos.py`. Con 12 archivos de producción, un solo implementer hace los cuatro grupos en orden.

## Decided

- RFZ: none
- ASM open: REV-03-ASM-01 a ASM-11, en `plan.md` `## Assumptions`; ASM-02 y ASM-10 son `any-answer: no` y van destacadas en el cierre
- app: `cd apps/api && uv run --no-sync uvicorn app.main:app --host 127.0.0.1 --port $PORT` · seed: none

## Already ran

- `pytest tests/escenarios/test_datos.py` sobre `f886ad0` → failed (25 fallan; pasan las 6 idas y vueltas de 0001 a 0007, que ya funcionan y quedan vigiladas) · `D:/Temp/rojo-rev03-api.log`
- `flutter test test/historial_por_tandas_test.dart` → failed (no aparece la segunda tanda) · `D:/Temp/rojo-rev03-app.log`
- RED-REVIEW → hallazgos H y M corregidos en una ronda · `specs/REV-03-datos/red-review.md`; quedan como observación F-06 (EXPLAIN), F-07 (CONCURRENTLY sin test propio), F-11 (barrido concurrente) y los L
- `plan-check.mjs` → passed

## Decisions of the main thread not written elsewhere

- Entorno: Postgres compartido en `127.0.0.1:8703` (club/club), base `club_rev03_test`, y `club_rev03_migraciones_test` que el test borra y crea; emulador de Firebase Auth en `127.0.0.1:9099` (no se baja ni se relanza). Los comandos de test llevan `TEST_DATABASE_URL="postgresql+psycopg://club:club@127.0.0.1:8703/club_rev03_test" FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`. Flutter: `export PATH="/d/projects/flutter/bin:$PATH"`.
- Máquina compartida y lenta: suites en background con log y `wait.mjs`; la suite entera de la API tarda 3 a 8 min, una vez al final; mutaciones con el subconjunto de `## Verification`; declarar con `rg_run` lo que use CPU.
- Los hooks del kit ubican la card por las rutas absolutas del prompt y no reconocen rutas entre backticks: en cada prompt a un subagente poné al menos una vez la ruta plana, precedida de un espacio (por ejemplo D:/Temp/w/rev03/specs/REV-03-datos/plan.md ); en shell, `cd /d/Temp/w/rev03 && ...`.
- REV-01 (en paralelo, rama `card/REV-01`) acota `pagina` a 1..10000 y cambia el formato de los errores de forma a `{"errores": …}`; al integrar, su test REV-01-H05-03 convive con `despues` porque `pagina` sigue (ASM-11). No toques `pagina` más allá de lo necesario.
- El hallazgo 12 no se corrige (migraciones de main), se declara en el cierre. No se pushea, no se abre PR, no se mergea: publicar queda «no se pudo correr».
- Matar procesos sólo por PID propio.
