# Tasks: CU-05 · Consultar perfil

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/usuarios/perfil_test.dart`.

## Phase 1: API

- [x] T001 `GET /yo` con DNI y fecha de nacimiento

## Phase 2: App

- [x] T002 [P] `Apariencia` y el tema de toda la app
- [x] T003 [P] Barra inferior en Home, Sedes, Reservas y Perfil
- [x] T004 `Sesion.refrescar` y Mi perfil con sus estados de error (H01-01, H03-01, H04-01, H05-01)
- [x] T005 Selector de modo oscuro (H01-02) y accesos de la cuenta (H01-03, H02-01)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T004. T002 y T003 no dependen entre sí. T004–T005 → T006–T007.
