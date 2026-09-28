# Tasks: CU-16 · Consultar sedes

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sedes/consultar_sedes_test.dart`.

## Phase 1: API

- [x] T001 Deportes de cada sede en `GET /sedes`, filtro `sede_id` y `numero` en `GET /espacios`, con sus tests

## Phase 2: App (CU-16-H01-01 a H05-01)

- [x] T002 Portadas del prototipo como imágenes de la app
- [x] T003 «Todas las sedes» con `TarjetaSede` (H01-01, H01-03, H05-01)
- [x] T004 La sede con sus canchas, sin canchas y ya no disponible (H01-02, H02-01, H03-01, H04-01)
- [x] T005 La pantalla de horarios con la cancha elegida (H01-04)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004 → T005 → T006–T007.
