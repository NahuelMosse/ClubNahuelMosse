# Tasks: CU-20 · Filtrar espacios deportivos

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sedes/filtrar_espacios_test.dart`.

## Phase 1: API

- [x] T001 `GET /espacios` con `deporte` y `tipo`, con su test

## Phase 2: App (CU-20-H01-01 a H06-01)

- [x] T002 `Espacios.activos` con deporte y tipo
- [x] T003 Chips de deporte y de tipo con el contador (H01-01, H01-02, H02-01, H03-01, H04-01)
- [x] T004 El filtro sigue en la sede y trae las canchas nuevas (H01-03, H01-04)
- [x] T005 Errores al filtrar sin cambiar la pantalla (H05-01, H06-01)
- [x] T006 Recongelar los escenarios de CU-16 con el contador del prototipo

## Phase 3: Polish

- [x] T007 Tests de widget, accesibilidad y capturas del paso 9
- [x] T008 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004–T006 → T007–T008.
