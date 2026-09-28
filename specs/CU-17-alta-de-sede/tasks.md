# Tasks: CU-17 · Alta de sede

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sedes/alta_sede_test.dart`
y `apps/api/tests/escenarios/test_alta_sede.py`.

## Phase 1: Setup

- [x] T001 Soporte de escenarios: entrar como administrador, elegir una hora, las sedes que ve un usuario
- [x] T002 Migración `0004`: nombre único entre sedes activas

## Phase 2: API

- [x] T003 `validar_sede` y `dar_de_alta_sede` con sus unitarios
- [x] T004 `SedesSql`, `GET /sedes` y `POST /sedes` con sus tests contra la base y el emulador (H01-03)

## Phase 3: App (CU-17-H01-01 a H04-01)

- [x] T005 `BarraAdmin` y el listado del panel (H01-01, H01-02)
- [x] T006 Formulario con selectores de hora y días, y validación por campo (H02-01, H03-01)
- [x] T007 Éxito con IR AL LISTADO y Crear otra sede (H01-04)
- [x] T008 Errores de conexión, servidor y sesión vencida (H04-01)

## Phase 4: Polish

- [x] T009 Tests de widget, accesibilidad y capturas del paso 9
- [x] T010 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001–T002 → T003 → T004 → T005 → T006–T008 → T009–T010.
