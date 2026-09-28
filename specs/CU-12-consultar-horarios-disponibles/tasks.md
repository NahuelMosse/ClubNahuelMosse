# Tasks: CU-12 · Consultar horarios disponibles

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/reservas/consultar_horarios_test.dart`.

## Phase 1: API

- [x] T001 `grilla` y `validar_consulta` con sus tests unitarios
- [x] T002 `GET /espacios/{id}/horarios` con su test de integración
- [x] T003 `POST /_pruebas/reservas` para los escenarios

## Phase 2: App (CU-12-H01-01 a H07-01)

- [x] T004 `Horarios.de` y la grilla con cancha, fecha y duración (H01-01, H01-02, H02-01, H03-01)
- [x] T005 Duración de 1 a 4 horas y la nota (H01-05, H04-01, H04-02, H04-03)
- [x] T006 Resumen, CONTINUAR y «Confirmá tu reserva» (H01-03, H01-04)
- [x] T007 Estados vacíos y errores (H05-01, H05-02, H06-01, H07-01)

## Phase 3: Polish

- [x] T008 Tests de widget, accesibilidad y capturas del paso 9
- [x] T009 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T004 → T005–T007 → T008–T009.
