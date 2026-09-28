# Tasks: CU-13 · Consultar canchas

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/reservas/consultar_canchas_test.dart`.

## Phase 1: API

- [x] T001 `validar_rango` con sus tests unitarios
- [x] T002 `GET /espacios/disponibles` con su test de integración

## Phase 2: App (CU-13-H01-01 a H05-01)

- [x] T003 «Buscar cancha» en el inicio y la pantalla con sus filtros
- [x] T004 Reglas del rango en la app (H03-01, H03-02, H03-03)
- [x] T005 Consulta, resultados, chips y aviso sin canchas (H01-01, H01-02, H01-04, H02-01)
- [x] T006 Cada cancha abre su grilla con el rango consultado (H01-03)
- [x] T007 Errores de conexión y de servidor (H04-01, H05-01)

## Phase 3: Polish

- [x] T008 Tests de widget, accesibilidad y capturas del paso 9
- [x] T009 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004–T007 → T008–T009.
