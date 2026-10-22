# Handoff · REV-06 · parte apps/mobile (T2, T3, T4, T6 Dart, T7 Dart)

Estado: no se escribió código ni tests; `flutter pub get` ya corrió en `apps/mobile`. PATH: `/d/projects/flutter/bin`.
Otro builder hace apps/api en paralelo: no tocarlo; commitear sólo rutas propias.

## Medición (script de grafo en /tmp/rev06-g3.mjs; si no está, rehacerlo: carpeta = primer segmento bajo lib/, archivos de la raíz = "(raiz)")
Ciclos hoy entre carpetas:
- (raiz)↔sesion: `sesion/firebase.dart` importa `configuracion.dart`.
- comun↔sesion: `comun/pantalla_acceso_denegado.dart` importa sesion/sesion y sesion/tarjeta_cuenta.
- reservas↔sesion: `sesion/pantalla_inicio_sesion.dart` importa `reservas/reserva_pendiente.dart` (que usa `Eleccion` de reservas).
- sesion↔usuarios: `sesion/pantalla_nueva_contrasena.dart` y `pantalla_recuperar_contrasena.dart` importan `usuarios/reglas_contrasena.dart` y `reglas_registro.dart`.
`comun` además importa `api` (dialogo_error) y `tema`: ambas carpetas no importan nada de lib. Decisión tomada (anotar en el Log como ASM de la lectura de REV-06-ASM-02): el test deja a `comun` importar sólo `api` y `tema`, que no importan nada de lib.

## Movimientos decididos (los tests de cards anteriores que importan estos paths NO llevan tag `@`; se les cambia el import y se anota en el Log, sin re-exports)
- `configuracion.dart` -> `comun/configuracion.dart` (importan: main.dart, sesion/firebase.dart).
- `comun/pantalla_acceso_denegado.dart` -> `sesion/pantalla_acceso_denegado.dart` (importan: app.dart, test/errores_compartidos_test.dart).
- `reservas/reserva_pendiente.dart` -> `sesion/reserva_pendiente.dart`, genérica `ReservaPendiente<T extends Object>` (reservas/pantalla_confirmar_reserva usa `ReservaPendiente<Eleccion>`; sesion/pantalla_inicio_sesion usa `ReservaPendiente<Object>`; app.dart `ReservaPendiente<Eleccion>()`; tests: accesibilidad_sesion_test, pantalla_inicio_sesion_test).
- `usuarios/reglas_registro.dart` y `usuarios/reglas_contrasena.dart` -> `comun/` (importan: sesion/*, usuarios/pantalla_*, tests perfil_test y reglas_registro_test).
- Revisar con el script que no queden otros ciclos tras mover.

## RED (commitear antes del código) — títulos exactos, cada uno en un solo literal
`test/arquitectura_test.dart` (escanea imports/exports de lib/, relativos y `package:clubnahuelmosse/`):
1. "ninguna carpeta de lib forma un ciclo de imports @REV-06-S4 @assumption:REV-06-ASM-02"
2. "los archivos de la raíz de lib cuentan como una carpeta en el test de ciclos @REV-06-S4 @assumption:REV-06-ASM-12" (función de ciclos sobre grafo sintético raiz↔a detecta ciclo + el grafo real no tiene ciclo por "(raiz)")
3. "la app tiene un test de imports y comun no importa otras carpetas de lib @REV-06-S2 @assumption:REV-06-ASM-02" (excepto api y tema)
4. "historial_reservas.dart no fuerza nulos con el operador ! @REV-06-S7 @assumption:REV-06-ASM-06" (hoy usa `!` en líneas ~33, 66-72: `estado!.name`, `desde!`, etc.; arreglar con variables locales/patrones)
5. "la zona del club se define una sola vez en la app @REV-06-S10 @assumption:REV-06-ASM-07" (`Duration(hours: 3)` aparece sólo en `comun/zona_club.dart`; hoy está en historial_reservas.dart:168 y 332, notificaciones/notificacion.dart:89, reservas/reglas_busqueda.dart:15, reservas/reservas.dart:110)
`test/registro_servicio_test.dart`:
6. "la pantalla de registro no arma el pedido HTTP: lo hace el servicio de registro @REV-06-S3 @assumption:REV-06-ASM-03" (pantalla_registro.dart no contiene `api.post(`/`'/registro'`; no importa ClienteApi directo salvo para el servicio)
7. "el servicio de registro manda los datos de la persona a /registro @REV-06-S3" (servicio en `lib/usuarios/registro.dart` envolviendo `ClienteApi`, como `sesion/recuperacion.dart`; hoy el post está en `pantalla_registro.dart:132`, mapea campos con `_Campo.clave` y `fechaIso`)
`test/tarjeta_reserva_test.dart`:
8. "el panel admin y Mis reservas muestran la reserva con la misma tarjeta @REV-06-S5 @assumption:REV-06-ASM-04" (widget `lib/comun/tarjeta_reserva.dart`; clon de 43 líneas entre `admin/pantalla_panel_admin.dart:~646` y `reservas/pantalla_mis_reservas.dart:~566`; ambos deben usarla; ojo: `comun` no puede importar espacios/reservas, así que el widget recibe datos planos, no modelos)

## Código
- Zona: `comun/zona_club.dart` (rule): `const desfaseDelClub = Duration(hours: 3)`, `DateTime aHoraDelClub(DateTime)` (toUtc().subtract) y `DateTime desdeHoraDelClub(DateTime)` (add); reemplazar los 5 usos.
- Registro: servicio `RegistroServicio` en `usuarios/registro.dart`; la pantalla lo llama (`PantallaRegistro` hoy recibe `api`; mantener la firma para los tests de cards anteriores, creando el servicio dentro o aceptando uno opcional).
- Conducta y pantallas sin cambios; capturas no se tocan.

## Cierre
`cd apps/mobile && flutter analyze && flutter test` en background (`/tmp/rev06-app-<n>.log`), una línea de Log por tarea en card.md (`- L<n> · <date> · T<n> · ...`), pantallas listas para el designer: ninguna (no hay lens visual en esta card).
