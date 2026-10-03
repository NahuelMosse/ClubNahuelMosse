# Tasks: TP-07 · Manejo de errores

**Input**: `plan.md`
**Tests**: los escenarios de la app están congelados en
`apps/mobile/integration_test/errores/errores_compartidos_test.dart`; los de la API, en
`apps/api/tests/escenarios/test_registro_de_errores.py`.

## Phase 1: API

- [x] T001 `RegistroDeErrores`: middleware que registra con fecha, método, ruta, código y usuario
  las excepciones no atrapadas, los 5xx y los 401, 403 y 409 (TP-07-SUP-06); `usuario_actual`
  deja el id en el estado del pedido

## Phase 2: App (TP-07-H01-01 a H07-01)

- [x] T002 Overlays compartidos de conexión (REINTENTAR y Volver) y de servidor (ACEPTAR) en
  `mostrarErrorDeRed`; `ClienteApi.limite` inyectable, 15 s por defecto (H01-01, H01-02, H02-01,
  H03-01, H04-01)
- [x] T003 Sesión expirada con «IR AL INICIO DE SESIÓN» (H05-01)
- [x] T004 «Acceso denegado» único, en `/admin/acceso-denegado` (`PantallaAccesoDenegado`, la de
  CU-14): toda ruta bajo `/admin` sin rol redirige ahí y un 403 de la API también; IR A MIS
  RESERVAS lleva a Mis reservas (H06-01, CU-14 FA4)
- [x] T005 «Esto cambió mientras tanto» en lugar del SnackBar en sede, horarios y confirmar
  reserva (H07-01)

## Phase 3: Polish

- [x] T006 Unitarios al 200 % en 360 del aviso y de las pantallas que cambiaron
- [x] T007 Capturas del paso 9 (360/430 × claro/oscuro)
- [x] T009 el log no lleva los parámetros de las consultas y una tarea de fondo que falla registra el código enviado
- [x] T010 un 409 después de un corte cuenta como éxito en registro, cancelar y anular (TP-07-SUP-08)
- [x] T011 «Acceso denegado» relee el perfil, ofrece «Cerrar sesión» y los 403 no navegan encima (TP-07-SUP-07)
- [ ] T008 `scripts/e2e.sh integration_test/errores/errores_compartidos_test.dart` en verde
  (pasada final en el emulador)

## Dependencies

T001 → T002 → T003 → T004 → T005 → T006–T008.
