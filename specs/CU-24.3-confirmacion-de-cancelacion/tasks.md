# Tasks: CU-24.3 · Recibir confirmación de cancelación

**Input**: `plan.md`
**Tests**: escenarios congelados en `apps/api/tests/escenarios/test_confirmacion_cancelacion.py` y `apps/mobile/integration_test/notificaciones/confirmacion_cancelacion_test.dart`.

## Phase 1: API

- [x] T001 Migración 0006 y mensaje del dominio
- [x] T002 `cancelar` encola la confirmación en la misma transacción (H01-01, H01-03, H04-01)
- [x] T003 Despacho de pendientes y `entregar` compartido (H03-01)
- [x] T004 La ruta de cancelar despacha después de responder; el barrido retoma lo pendiente

## Phase 2: App

- [x] T005 Ruta del aviso según su tipo y `historial` en Mis reservas (H01-02)
- [x] T006 El panel no muestra la confirmación con la persona en Mis reservas (H02-01)

## Phase 3: Polish

- [x] T007 Tests de widget al 200 % en 360 y 430
- [ ] T008 `scripts/e2e.sh` en el emulador: pendiente de la pasada final

## Dependencies

T001 → T002 → T003 → T004; T004 → T005 → T006 → T007 → T008.
