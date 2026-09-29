# Tasks: CU-10 · Cancelar reserva

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/reservas/cancelar_reserva_test.dart`.

## Phase 1: API

- [x] T001 `POST /reservas/{id}/cancelar` con su test de integración

## Phase 2: App (CU-10-H01-01 a H05-01)

- [x] T002 CANCELAR en la tarjeta, la confirmación y el éxito (H01-01, H01-02, H02-01)
- [x] T003 Errores de conexión y de servidor (H03-01, H04-01)
- [x] T004 La reserva que cambió o empezó (H05-01)

## Phase 3: Polish

- [x] T005 Tests de widget, accesibilidad y capturas del paso 9
- [x] T006 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003–T004 → T005–T006.
