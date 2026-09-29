# Tasks: CU-09 · Reservar cancha

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/reservas/reservar_test.dart` y `apps/api/tests/escenarios/test_reservar.py`.

## Phase 1: API

- [x] T001 `validar_reserva` con sus tests unitarios
- [x] T002 `POST /reservas`: validación, precio, superposición e idempotencia (H01-04, H01-05, H01-06, H01-08, H02-02)

## Phase 2: App

- [x] T003 CONFIRMAR RESERVA y el comprobante (H01-01, H01-03, H01-09)
- [x] T004 El horario que se ocupó mientras se confirmaba (H01-02, H02-01)
- [x] T005 Cancelar y el botón deshabilitado sin horario (H01-07, H03-01)
- [x] T006 La sesión vencida y la reserva pendiente (H04-01)
- [x] T007 Errores de conexión y de servidor (H05-01, H05-02)

## Phase 3: Polish

- [x] T008 Tests de widget, accesibilidad y capturas del paso 9
- [x] T009 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004–T007 → T008–T009.
