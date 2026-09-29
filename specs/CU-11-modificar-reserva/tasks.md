# Tasks: CU-11 · Modificar reserva

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/reservas/modificar_reserva_test.dart` y `apps/api/tests/escenarios/test_modificar_reserva.py`.

## Phase 1: API

- [x] T001 `reserva_id` en la grilla, con su test de integración (SUP-07)
- [x] T002 `POST /reservas/{id}/modificar` con sus tests de integración (H01-03)

## Phase 2: App (CU-11-H01-01 a H06-01)

- [x] T003 MODIFICAR en la tarjeta y la grilla en modo modificación (H04-01)
- [x] T004 «Confirmá el cambio», guardar y desistir (H01-01, H01-02, H02-01)
- [x] T005 El horario ocupado y la reserva que cambió (H03-01, H05-01, H05-02)
- [x] T006 Errores de conexión y de servidor (H06-01)

## Phase 3: Polish

- [x] T007 Tests de widget, accesibilidad y capturas del paso 9
- [x] T008 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001–T002 → T003 → T004 → T005–T006 → T007–T008.
