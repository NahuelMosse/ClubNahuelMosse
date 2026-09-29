# Tasks: CU-22 · Editar espacio deportivo

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/espacios/editar_espacio_test.dart`.

## Phase 1: API

- [x] T001 `PUT /espacios/{id}` con sus tests de integración (SUP-01 a SUP-03)

## Phase 2: App (CU-22-H01-01 a H07-01)

- [x] T002 «Editar» en la tarjeta y el formulario con los datos cargados (H01-01, H01-02, H01-03, H02-01)
- [x] T003 El precio inválido y sin cambios (H03-01, H04-01)
- [x] T004 El espacio dado de baja y los errores de red (H05-01, H06-01)
- [x] T005 DAR DE BAJA EL ESPACIO abre la confirmación de CU-23 (H07-01)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003–T005 → T006–T007.
