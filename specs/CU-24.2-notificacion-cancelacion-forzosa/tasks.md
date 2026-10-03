# Tasks: CU-24.2 · Recibir notificación de cancelación forzosa

**Input**: `plan.md`
**Tests**: escenarios congelados en `apps/api/tests/escenarios/test_cancelacion_forzosa.py` y `apps/mobile/integration_test/notificaciones/cancelacion_forzosa_test.dart`.

## Phase 1: API

- [x] T001 Migración 0007 y mensaje del dominio
- [x] T002 `encolar_cancelacion_forzosa` con agrupado por aviso nuevo, bloqueo por persona e idempotencia (H02-01, H03-01)
- [x] T003 `anular` encola en la misma transacción; el historial trae el envío (H01-01, H01-03, H05-01)
- [x] T004 La ruta de anular despacha después de responder; el push de anulación lleva clave de reemplazo (H01-01, H04-01)

## Phase 2: App

- [x] T005 El detalle de administración muestra el envío en la trazabilidad (H01-03)

## Phase 3: Polish

- [x] T006 Tests unitarios y de widget al 200 % en 360 y 430
- [x] T007 `sh scripts/test.sh`
- [ ] T008 `scripts/e2e.sh` en el emulador: pendiente de la pasada final

## Dependencies

T001 → T002 → T003 → T004; T003 → T005 → T006 → T007 → T008.
