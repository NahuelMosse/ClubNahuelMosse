# Tasks: CU-08 · Consultar historial de reservas

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/reservas/mis_reservas_test.dart`.

## Phase 1: API

- [x] T001 `GET /reservas` con próximas e historial, con su test de integración

## Phase 2: App (CU-08-H01-01 a H03-02)

- [x] T002 `Reservas.mias` y la tarjeta de reserva (H01-01, H01-02)
- [x] T003 Historial con estados y motivos (H01-03, H01-04, H01-05)
- [x] T004 Avisos sin reservas (H02-01, H02-02)
- [x] T005 Errores de conexión y de servidor (H03-01, H03-02)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003–T005 → T006–T007.
