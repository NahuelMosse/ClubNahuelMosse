# Tasks: CU-04 · Cambiar contraseña

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/usuarios/cambiar_contrasena_test.dart`.

## Phase 1: Setup

- [x] T001 Soporte de escenarios: API intermedia y consultas a Firebase
- [x] T002 Migración 0002 con `contrasena_cambiada_en`

## Phase 2: API

- [x] T003 [P] Caso de uso `cambiar_contrasena` y sus unitarios
- [x] T004 [P] `contrasena_correcta` y `cambiar_contrasena` en `ProveedorFirebase`
- [x] T005 `PUT /yo/contrasena` y sus tests contra el emulador

## Phase 3: App (CU-04-H01-01 a H07-01)

- [x] T006 `ClienteApi.put` y `Sesion.cambiarContrasena`
- [x] T007 Modal compartido con sesión expirada
- [x] T008 Pantalla de cambio de contraseña y bloque SEGURIDAD de Mi perfil

## Phase 4: Polish

- [x] T009 Tests de widget, accesibilidad y capturas del paso 9
- [x] T010 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001–T002 → T003–T005 → T006–T008 → T009–T010. T003 y T004 no dependen entre sí.
