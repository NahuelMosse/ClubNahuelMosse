# Tasks: CU-24.1 · Recibir notificación recordatoria

**Input**: `plan.md`
**Tests**: escenarios congelados en `apps/api/tests/escenarios/test_recordatorio.py` y `apps/mobile/integration_test/notificaciones/notificaciones_test.dart`.

## Phase 1: API

- [x] T001 Migración 0005 y dominio del aviso
- [x] T002 Puertos, casos de uso y `enviar_recordatorios` (H01-01, H03-01, H05-01, H05-02)
- [x] T003 `NotificacionesSql`, `CanalNulo` y `CanalFcm`
- [x] T004 Endpoints de dispositivos y centro (H04-01, H04-02) y `/_pruebas`
- [x] T005 Barrido en segundo plano

## Phase 2: App

- [x] T006 Modelo, repositorio y estado del centro; sistema de notificaciones simulado y FCM
- [x] T007 Centro, estado vacío y «Notificaciones desactivadas» (H01-03, H03-01, H03-02)
- [x] T008 Panel superior y campana (H02-01, H04-01, H04-02)
- [x] T009 Abrir Mis reservas con la reserva resaltada (H01-02)

## Phase 3: Polish

- [x] T010 Tests de widget al 200 % en 360, accesibilidad y capturas del paso 9
- [x] T011 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004 → T005; T004 → T006 → T007 → T008 → T009 → T010 → T011.
