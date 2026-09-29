# Tasks: CU-18 · Editar sede

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sedes/editar_sede_test.dart`.

## Phase 1: API

- [x] T001 `PUT /sedes/{id}` con sus tests de integración (SUP-01 a SUP-04)

## Phase 2: App (CU-18-H01-01 a H07-01)

- [x] T002 «Editar sede» en la tarjeta y el formulario con los datos cargados (H01-01, H01-02, H02-01)
- [x] T003 El campo vacío y GUARDAR CAMBIOS deshabilitado (H03-01)
- [x] T004 Las reservas que quedan afuera (H04-01, H04-02, H04-03)
- [x] T005 La sede dada de baja y los errores de red (H05-01, H06-01)
- [x] T006 DAR DE BAJA LA SEDE abre la confirmación de CU-19 (H07-01)

## Phase 3: Polish

- [x] T007 Tests de widget, accesibilidad y capturas del paso 9
- [x] T008 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003–T006 → T007–T008.
