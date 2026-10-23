# Handoff REV-03 · ronda g

## Hecho (commits en kit-5 del worktree)
- Gate: `migrate-upgrade` apunta a test_datos_migraciones.py; línea `mutate apps/api/app/dominio/reservas.py` y el archivo en T2; pyproject.toml en T1; lint ampliado (ruff format de los tests nuevos y `dart format` de los dos tests Dart); mutate de 0008 y env.py usan test_datos_migraciones.py + test_datos_migraciones_lock.py.
- Reemplazo L31: test_datos_migraciones_lock.py (lock_timeout con base propia). 9 passed en 7 min.
- K4 declarados L32 a L37 (clones con un test congelado).
- Mutaciones corridas a mano con la forma de verify (once.mjs "mutate <f>" -- "node mutate.mjs <f> --since 1ad6d71f31397463d9cf4aeb34f143bbb4133529~1 --equivalents specs/REV-03-datos/equivalents.md --parallel 2 -- sh D:/Temp/w/herramientas/pytest-api.sh <args>"): dominio/notificaciones.py 5/5, infraestructura/notificaciones.py 2/2 (exit 0). En curso al escribir esto: migraciones/env.py y 0008 (logs /tmp/mutm-env.log, /tmp/mutm-0008_indices_y_cola_recuperable.log; resultado en `.validation/once/*.log`).

## Hallazgos del último verify (/tmp/rev03-gate.log, 62 min)
- passed: lint, app-suite, migrate-upgrade (30 min por la carga). exit 1: suite y scenarios (fallan tests congelados reemplazados y test_requisitos_no_funcionales "toda operación sin usuario se rechaza", a revisar si es de la card), attacks (foreign Host, 25-S2, REV-01: se deja).
- Las líneas mutate de verify no terminaron en 60 min con 10 líneas en paralelo (baseline lento: cada test de migración tarda ~45 s). `mutate aplicacion/notificaciones.py`: exit 3, ningún operador aplica.
- required: falta `design/line.md` (I-line, card toca pantallas) y clones K4 en código de producción (mobile reservas.dart/pantalla_mis_reservas.dart, app/interfaz/reservas.py, infraestructura/reservas.py, dominio/reservas.py vs interfaz/reservas.py): extraer o declarar con why.

## Falta
1. Leer el resultado de las mutaciones de env.py y 0008; matar sobrevivientes con tests en archivos nuevos (no congelados) o declarar en equivalents.md (0008 líneas 12-13 equivalentes probables; env.py `transaction_per_migration` True->False).
2. Mutaciones de dominio/reservas.py, infraestructura/reservas.py, interfaz/marcador.py, interfaz/reservas.py y los tres .dart (verify las salteó: "not required by grade production" para esos).
3. Revisar suite/scenarios: qué falla fuera de los reemplazados.
4. required.mjs: I-line y K4 de producción.
5. Env: FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:8702, PATH="/d/projects/flutter/bin:$PATH". No pushear.
