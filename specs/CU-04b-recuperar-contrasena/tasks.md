# Tasks: CU-04b · Recuperar contraseña

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sesion/recuperar_contrasena_test.dart`.

## Phase 1: Setup

- [x] T001 Soporte de escenarios: buzón de la corrida y apertura por el enlace
- [x] T002 Migración 0003 con enlaces y correos; `PRUEBAS=1` en `scripts/e2e.sh`

## Phase 2: API

- [x] T003 [P] Casos de uso de pedir, consultar y usar el enlace, con sus unitarios
- [x] T004 [P] `EnlacesSql`, `BuzonSql` y `CorreoSmtp`
- [x] T005 Rutas de `/recuperacion` y de `/_pruebas`, y sus tests contra el emulador

## Phase 3: App (CU-04b-H01-01 a H07-01)

- [x] T006 Pantalla de resultado, reglas y barra de acción compartidas con CU-04
- [x] T007 `Recuperacion` y la pantalla para pedir el enlace (H02, H03, H06, H07)
- [x] T008 Deep link y pantalla de contraseña nueva (H01, H04, H05)

## Phase 4: Polish

- [x] T009 Tests de widget, accesibilidad y capturas del paso 9
- [x] T010 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001–T002 → T003–T005 → T006–T008 → T009–T010. T003 y T004 no dependen entre sí.
