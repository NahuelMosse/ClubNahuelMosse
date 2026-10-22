# Handoff T4 (apps/mobile)

Hecho: `apps/mobile/test/operacion_app_test.dart` (15 tests, títulos de la card, RED). Falta todo el código de T4.

API que los tests suponen (no existe todavía):
- `lib/comun/errores_no_manejados.dart`: `typedef RegistroDeError = void Function(Object, StackTrace?)`; variable global asignable `RegistroDeError registroDeErrores` (por defecto a consola de depuración); `registrarError(Object, StackTrace?)` que la llama; `instalarCapturaDeErrores([RegistroDeError? destino])` (FlutterError.onError y PlatformDispatcher.onError, este devuelve true); `correrProtegido(void Function() cuerpo, [RegistroDeError? destino])` (runZonedGuarded).
- `cliente_api.dart`: `limite` por defecto 60 s; `ServidorSinRespuesta` (excepción distinta de `SinConexion`) cuando se agota el límite (TimeoutException); `ClienteApi` expone un `ValueListenable<bool> despertando` (true si un pedido pasa de 5 s); `ErrorDelServidor` suma `referencia` (de `{"referencia"}` del 500/503).
- `dialogo_error.dart`: `ServidorSinRespuesta` -> «El servidor no responde. Probá de nuevo en unos minutos.»; `ErrorDelServidor` con referencia -> el texto incluye la referencia; sin red sigue «Revisá tu conexión a internet».
- Aviso «despertando … hasta un minuto»: hay que montarlo en `app.dart` (MaterialApp.builder, Stack ya existe en línea ~519), no está en la lista de T4: declarar en el Log como OUT/cambio mínimo.
- `sesion.dart`: `retomar()` espera hasta 60 s (quitar `limiteAlRetomar`), y ante `ErrorDelServidor`/`ServidorSinRespuesta`/`SinConexion` relanza en vez de devolver null; `main.dart` debe mostrar el error con reintento, no el login. `CredencialesInvalidas` sigue cerrando sesión.
- `main()` -> `correrProtegido(() => arrancar(...))`; `arrancar` llama `instalarCapturaDeErrores()`.
- Los cuatro lugares: detalle_reserva (2 `.ignore()` -> `registrarError`), centro.dart (4 `on Exception` sin rastro: líneas ~189, 210, 265, 277), editar_espacio `_leerCatalogo`, inicio `_releerSinAvisar`; todos `registrarError(e, pila)`.

Pendiente de verificar: el test del inicio adivina el botón `CANCELAR RESERVA`; si no existe, reemplazar con archivo nuevo mismo tag y registrar `replaces:` en el Log. Tests de pantallas usan `SesionFalsa`, `SistemaSimulado` (verificar nombres/constructores al compilar).
Gate: `cd apps/mobile && PATH=/d/projects/flutter/bin:$PATH flutter analyze && flutter test`, y los 3 `mutate` de Dart con `node .claude/tools/once.mjs`.
