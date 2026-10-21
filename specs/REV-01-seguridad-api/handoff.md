# Handoff — REV-01 · seguridad de la API

- card: `specs/REV-01-seguridad-api/` · snapshot `proposed`
- branch: `card/REV-01`, worktree `D:/Temp/w/rev01` · base commit: `138bc54` · plan commit: `2a31441` · tests-in-red commit: `2a31441` (evento en `c2ec37a`)
- grade: `production` · modules: `ui, api, data, infra, observability, security-l2` · lane: `normal`

## Groups, in order (from `plan.md` `## File map`)

1. `entradas y límites` — `interfaz/entradas.py`, `interfaz/limites.py`, `interfaz/{registro,recuperacion,sesion,sedes,espacios,reservas}.py`, `aplicacion/reservas.py` — tests: `@REV-01-H05`, `@REV-01-H06`
2. `registro, cabeceras y arranque` — `interfaz/registro_errores.py`, `interfaz/protecciones.py`, `interfaz/salud.py`, `config.py`, `main.py` — tests: `@REV-01-H09-02`, `@REV-01-H09-03`, `@REV-01-H09-04`, `@REV-01-H16`, `@REV-01-H25-01`
3. `correo, emulador y dispositivos` — `infraestructura/correo.py`, `infraestructura/identidad.py`, `infraestructura/notificaciones.py` (y la interfaz de dispositivos si hace falta) — tests: `@REV-01-H01`, `@REV-01-H09-01`, `@REV-01-H25-02`, `@REV-01-H25-03`
4. `dependencias, contrato y despliegue` — `uv.lock`, `apps/api/openapi.json`, `render.yaml`, `apps/api/README.md`, `tests/conftest.py` (una línea nueva) — tests: `@REV-01-H07`, `@REV-01-H16-01`

Todas las rutas de los grupos 1 a 3 cuelgan de `apps/api/app/`. Los escenarios están en `apps/api/tests/escenarios/test_seguridad_api.py`.

## Decided

- RFZ: none
- ASM open: REV-01-ASM-01 a ASM-12, en `plan.md` `## Assumptions`; ASM-04 y ASM-05 son `any-answer: no` y van destacadas en el cierre (ASM-05: la documentación interactiva en la nube la decide una persona)
- app: `cd apps/api && uv run --no-sync uvicorn app.main:app --host 127.0.0.1 --port $PORT` · seed: none

## Already ran

- `pytest tests/escenarios/test_seguridad_api.py` sobre `2a31441` → failed (49 fallan, 9 controles pasan) · `D:/Temp/rojo-rev01b.log`
- RED-REVIEW → 11 hallazgos corregidos en una ronda · `specs/REV-01-seguridad-api/red-review.md`
- `plan-check.mjs` → passed

## Decisions of the main thread not written elsewhere

- Entorno: Postgres compartido en `127.0.0.1:8703` (club/club), base `club_rev01_test`; emulador de Firebase Auth ya corriendo en `127.0.0.1:9099` (no se baja ni se relanza). Los comandos de test llevan `TEST_DATABASE_URL="postgresql+psycopg://club:club@127.0.0.1:8703/club_rev01_test" FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`.
- Máquina compartida y lenta: suites y builds en background con log y `wait.mjs`; la suite entera de la API tarda 3 a 8 min, se corre una vez al final; las mutaciones usan el subconjunto de `## Verification`. Declarar con el MCP `resource-governor` (`rg_run`) lo que use CPU.
- El emulador Android no está garantizado: los e2e de registro y recuperación (C1) corren con `sh /d/Temp/e2e-archivos.sh /d/Temp/w/rev01 rev01 integration_test/<archivo>.dart` si `adb devices` muestra `emulator-5554`; si no, «no se pudo correr».
- No se pushea ni se abre PR: publicar queda «no se pudo correr», declarado en `closing.md`. No se mergea nada a `kit-3` ni a `main`.
- El hook `delegate-code` clasifica `apps/api/tests/**` como código de producción (sólo reconoce `tests/` en la raíz): el implementer escribe ahí los unitarios sin problema; el hilo principal no puede editar los escenarios, que están congelados igual.
- REV-02 parte después de esta rama y toca `main.py` y `registro_errores.py`: dejarlos con funciones chicas y sin lógica de más.
- Matar procesos sólo por PID propio.
