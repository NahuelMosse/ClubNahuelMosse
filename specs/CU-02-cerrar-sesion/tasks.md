# Tasks: CU-02 · Cerrar sesión

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sesion/cierre_sesion_test.dart`.

## Phase 1: Setup

- [x] T001 Soporte de escenarios: entrar como usuario y reabrir la app

## Phase 2: Componentes

- [x] T002 [P] `AvatarIniciales`, `Insignia` y `BotonContorno`
- [x] T003 Tarjeta de la cuenta con sus accesos por rol (H01-01, H03-01)

## Phase 3: Pantallas

- [x] T004 Avatar en el Home y en el panel de administración
- [x] T005 Mi perfil con «CERRAR SESIÓN» y destino de Mis reservas (H02-01)
- [x] T006 Rutas por rol que escuchan a la sesión (H01-02)

## Phase 4: Polish

- [x] T007 Tests de widget, accesibilidad y capturas del paso 9
- [x] T008 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004–T006 → T007–T008.
