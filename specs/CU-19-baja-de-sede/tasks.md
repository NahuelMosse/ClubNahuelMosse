# Tasks: CU-19 · Dar de baja sede

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sedes/baja_sede_test.dart`.

## Phase 1: API

- [x] T001 `DELETE /sedes/{id}` con sus tests de integración (SUP-01, SUP-02, SUP-04, SUP-05)

## Phase 2: App (CU-19-H01-01 a H05-01)

- [x] T002 La confirmación y la baja desde la edición (H01-01, H01-02, H02-01)
- [x] T003 «Dar de baja» en la tarjeta del listado (H01-03)
- [x] T004 La sede ya dada de baja y la sede con reservas (H03-01, H04-01)
- [x] T005 Errores de red (H05-01)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003–T005 → T006–T007.
