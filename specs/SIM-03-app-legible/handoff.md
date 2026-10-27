# Handoff SIM-03

Hecho (commits c237874 RED, c905f71 T1 + T2 movimiento, a6ddb22 T2 diálogos, T3 en el último):
- RED: apps/mobile/test/codigo_legible_test.dart (7 tests; escáner de largo de funciones con llaves).
- T1 completo. test/analysis_options.yaml apaga tres reglas sólo en test/.
- T2 completo: comun/movimiento.dart es índice de comun/movimiento/*; diálogos de baja en admin/dialogos_de_baja.dart, confirmarCancelacion en reservas/confirmar_cancelacion.dart; comun/dialogo_error.dart publica `ModalDeAviso`. Los dos tests congelados cambiaron sólo imports.
- T3 completo: lib/rutas.dart (clase `Rutas`, `router(navegador:, inicio:)`, un método por sección), lib/redireccion.dart (`redirigirSegunRol`, pura); app.dart sólo arma `Rutas(...).router(...)`.

Pendiente: T4, piezas de builds largos. `flutter test test/codigo_legible_test.dart` aún falla en «ninguna función de lib pasa de 80 líneas» y «las piezas de un build largo…» (~30 funciones, ver L8: dialogo_anular_reserva, pantalla_detalle_reserva, pantalla_editar_espacio, pantalla_formulario_sede, tarjeta_reserva_admin, ficha_socio, resultado, panel_avisos, pantalla_horarios, hero_de_inicio, …). Al partirlas, sumar sus archivos a la línea T4 de la card. Los métodos de rutas.dart ya están bajo 80 líneas (revisar `_deSedes`, `_deReservas`, `_deSedesAdmin`, `_deEspaciosAdmin` con el test).

Fallas ajenas ya vistas: interfaz_accesible_test «con un dato completado…» (registro sin GoRouter), movimiento_pantallas_test RED-04-S14, tarjeta_cuenta_test «cada rol entra sólo a sus pantallas» (busca «PANEL ADMIN» en /admin; confirmar contra la base con git worktree, el hook veta stash). La suite tiene 25 fallas en la base d521ed5.
Gate: `flutter analyze --no-pub` (limpio), `dart format lib`, `flutter test test/codigo_legible_test.dart`; `captures` y `fmt` se corren con verify.mjs.
