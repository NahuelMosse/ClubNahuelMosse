# Tasks: CU-03 · Registrar usuario

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/registro/registro_test.dart`
y `apps/api/tests/escenarios/test_registro.py`.

## Phase 1: Setup

- [ ] T001 Proyecto Flutter, fuentes del prototipo y análisis estricto en `apps/mobile/`
- [ ] T002 `firebase-tools` en `package.json` y `firebase.json` para el emulador de Auth
- [ ] T003 `scripts/e2e.sh` levanta base, emulador de Auth, API y emulador de Android

## Phase 2: Foundational

- [ ] T004 [P] Tema claro y oscuro con los tokens del prototipo en `lib/tema/`
- [ ] T005 [P] Campo, botones, barra y overlays de error en `lib/comun/`
- [ ] T006 [P] `ClienteApi` con sin conexión y error del servidor en `lib/api/cliente_api.dart`
- [ ] T007 Conexión por pedido y `crear_app()` en `apps/api/app/`

## Phase 3: Registro (CU-03-H01-01 a H03-02)

- [ ] T008 [P] Reglas del registro en `app/dominio/usuarios.py` y unitarios
- [ ] T009 [P] Las mismas reglas en `lib/usuarios/reglas_registro.dart` y unitarios
- [ ] T010 Caso de uso `registrar` con compensación de la cuenta de Firebase
- [ ] T011 `ProveedorFirebase` y `UsuariosSql`
- [ ] T012 `POST /registro` con 201, 409 y 422 (H01-02, H03-01, H03-02)
- [ ] T013 Pantalla de registro con validación al salir de cada campo (H01-01, H02-01)
- [ ] T014 Pantalla de éxito e inicio de sesión mínimo con «COMENZAR» (H01-01)

## Phase 4: Polish

- [ ] T015 Protecciones del borde de la API y sus tests
- [ ] T016 Accesibilidad con tests de widget y capturas del paso 9
- [ ] T017 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001–T003 → T004–T007 → T008–T014 → T015–T017. T008 y T009 no dependen entre sí.
