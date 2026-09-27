# Tasks: CU-01 · Iniciar sesión

**Input**: `plan.md`
**Tests**: los escenarios están congelados en `apps/mobile/integration_test/sesion/inicio_sesion_test.dart`.

## Phase 1: Setup

- [x] T001 `firebase_core` y `firebase_auth` en la app; Kotlin 2.3.21 y `compilerOptions` en Android
- [x] T002 `Configuracion` con `AUTH_EMULADOR` y `FIREBASE_*`; `iniciarFirebase` por instancia
- [x] T003 Soporte de escenarios: cuenta por la API, API que falla, sin red, admin de la corrida

## Phase 2: API

- [x] T004 [P] `Perfil`, `perfil_autenticado` y sus unitarios
- [x] T005 [P] `uid_del_token`, `perfil_activo`, `id_activo_por_correo`, `hacer_admin`
- [x] T006 `GET /yo` con `usuario_actual` (401 sin token válido o sin perfil activo)
- [x] T007 `sembrar_admin` y el comando; `scripts/e2e.sh` lo corre antes de la API

## Phase 3: App (CU-01-H01-01 a H06-01)

- [x] T008 `ClienteApi.get` con token; `Sesion` con iniciar, retomar y cerrar
- [x] T009 Pantalla de inicio de sesión: errores por campo, aviso genérico, overlays (H02, H03, H05, H06)
- [x] T010 Rutas por rol y destinos: Home, panel y recuperar contraseña (H01-01, H01-02, H04-01)
- [x] T011 Arranque con la sesión retomada

## Phase 4: Polish

- [x] T012 Tests de widget, accesibilidad y capturas del paso 9
- [x] T013 `scripts/test.sh` y `scripts/e2e.sh` en verde

## Dependencies

T001–T003 → T004–T007 → T008–T011 → T012–T013. T004 y T005 no dependen entre sí.
