# Tasks: CU-23 · Baja de espacio deportivo

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/espacios/baja_espacio_test.dart`.

## Phase 1: API

- [x] T001 `DELETE /espacios/{id}` con sus tests de integración (SUP-02 a SUP-04)

## Phase 2: App (CU-23-H01-01 a H03-01)

- [x] T002 «Baja» en la tarjeta, la confirmación y el aviso (H01-01, H01-02, H01-03)
- [x] T003 Cancelar (H02-01)
- [x] T004 Errores de red, el espacio ya dado de baja y con reservas (H03-01, SUP-01, SUP-04)
- [x] T005 La baja desde la edición (CU-22-SUP-04)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003–T005 → T006–T007.
