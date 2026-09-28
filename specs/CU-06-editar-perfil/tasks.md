# Tasks: CU-06 · Editar perfil

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/usuarios/editar_perfil_test.dart`.

## Phase 1: API

- [x] T001 Reglas de datos personales compartidas con el registro y `validar_edicion`
- [x] T002 `editar_perfil`, `UsuariosSql.actualizar` y `PUT /yo` con sus tests

## Phase 2: App (CU-06-H01-01 a H03-01)

- [x] T003 `Sesion.editarPerfil`
- [x] T004 Formulario de edición con el correo deshabilitado (H01-01, H01-02)
- [x] T005 Errores de formato, de DNI repetido y de red (H02-01, H03-01)

## Phase 3: Polish

- [x] T006 Tests de widget, accesibilidad y capturas del paso 9
- [x] T007 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001 → T002 → T003 → T004–T005 → T006–T007.
