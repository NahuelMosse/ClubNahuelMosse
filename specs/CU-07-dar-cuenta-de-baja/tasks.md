# Tasks: CU-07 · Dar cuenta de baja

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/usuarios/baja_cuenta_test.dart`
y `apps/api/tests/escenarios/test_baja_cuenta.py`.

## Phase 1: Setup

- [x] T001 Modo «lenta» de la API intermedia

## Phase 2: API

- [x] T002 `dar_de_baja` y `UsuariosSql.dar_de_baja` con sus unitarios (H01-02)
- [x] T003 `DELETE /yo` y sus tests contra la base y el emulador

## Phase 3: App (CU-07-H01-01 a H04-01)

- [x] T004 `ClienteApi.delete` y `Sesion.darDeBaja`
- [x] T005 Confirmación con ELIMINAR CUENTA y el botón «ELIMINANDO TU CUENTA…» (H01-01, H01-03)
- [x] T006 Errores de conexión, servidor y sesión vencida (H03-01, H04-01)

## Phase 4: Polish

- [x] T007 Tests de widget, accesibilidad y capturas del paso 9
- [x] T008 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004 → T005–T006 → T007–T008.
