# Handoff — REV-05 · Básquet en el catálogo

- card: `specs/REV-05-basquet-en-el-catalogo/` · snapshot `proposed`
- branch: `card/REV-05`, worktree `D:/Temp/w/rev05` · base commit: `138bc54` · plan commit: `8f752a4` · tests-in-red commit: `8f752a4` (evento en `f956f86`)
- grade: `production` · modules: `ui, api, data, infra, observability, security-l2` · lane: `normal`

## Groups, in order (from `plan.md` `## File map`)

1. `catálogo e íconos` — `apps/api/app/dominio/espacios.py`, `apps/mobile/lib/espacios/iconos.dart`, `apps/mobile/lib/sedes/fotos.dart`, `apps/mobile/test/soporte/montar.dart` (una línea), `apps/api/README.md` — tests: `apps/api/tests/escenarios/test_basquet.py`, `apps/mobile/test/basquet_test.dart`

## Decided

- RFZ: none
- ASM open: REV-05-ASM-01 a ASM-03, en `plan.md`
- app: none · seed: none

## Already ran

- `pytest tests/escenarios/test_basquet.py` → failed (4 de 4) · `D:/Temp/rojo-rev05-api.log`
- `flutter test test/basquet_test.dart` → failed (2 de 2) · `D:/Temp/rojo-rev05-app.log`
- RED-REVIEW → M y una L corregidos; queda L: ningún test ve Básquet en una pantalla (lo cubren las capturas del paso 9) · `specs/REV-05-basquet-en-el-catalogo/red-review.md`

## Decisions of the main thread not written elsewhere

- Entorno: base `club_rev05_test` en `127.0.0.1:8703` (club/club), emulador de Auth en `127.0.0.1:9099`; los comandos llevan `TEST_DATABASE_URL="postgresql+psycopg://club:club@127.0.0.1:8703/club_rev05_test" FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`. Flutter: `export PATH="/d/projects/flutter/bin:$PATH"`.
- Capturas del paso 9: si alguna vista del filtro o del alta muestra el catálogo completo, se regenera sólo esa (`flutter test --update-goldens test/capturas/<archivo>_capturas.dart`) y se mira.
- Los hooks del kit ubican la card por las rutas absolutas del prompt y no reconocen rutas entre backticks: en cada prompt a un subagente poné al menos una vez la ruta plana, precedida de un espacio (por ejemplo D:/Temp/w/rev05/specs/REV-05-basquet-en-el-catalogo/plan.md ); en shell, `cd /d/Temp/w/rev05 && ...`.
- No se pushea, no se abre PR, no se mergea: publicar queda «no se pudo correr». Matar procesos sólo por PID propio.
