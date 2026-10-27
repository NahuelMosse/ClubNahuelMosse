# Handoff SIM-03

Hecho (commits c237874 RED, c905f71 T1 + T2 movimiento):
- RED: apps/mobile/test/codigo_legible_test.dart (7 tests; escáner de largo de funciones con llaves; router esperado en `lib/rutas.dart`).
- T1 completo. test/analysis_options.yaml apaga tres reglas sólo en test/ para no tocar tests congelados.
- T2 movimiento: lib/comun/movimiento.dart es índice con `export ... show`; piezas en lib/comun/movimiento/ (tiempos.dart tiene Movimiento y arrancarUnaVez).

Pendiente:
- T2 dialogo_error: NO hecho. interfaz_accesible_test y movimiento_pantallas_test (congelados) importan confirmarBajaDeSede/confirmarBajaDeEspacio/confirmarCancelacion desde comun/dialogo_error.dart; moverlos cambia esos imports. Decisión humana (alternativa: mover sólo mostrarHorario*, mostrarSedeConReservas, mostrarEspacioConReservas, mostrarCancelada, mostrarReservaAnulada, confirmarHorarioNuevo, previa publicación de `_Modal` como `ModalDeAviso`).
- T3 (router a lib/rutas.dart) y T4 (piezas de builds largos): no empezados. La prueba de 80 líneas encuentra ~30 funciones, no sólo las 6 de T4 (ver L8).

Estado de la suite (flutter test en apps/mobile): 25 fallas ya existen en la base d521ed5 (rediseno/*, limpieza_*, etc.); con los cambios hay 28: las 3 de codigo_legible_test que esperan T3/T4. flutter analyze --no-pub: limpio.
Gate: `flutter analyze --no-pub`, `flutter test test/codigo_legible_test.dart`; el hook veta correr bruto la línea `captures` y `fmt` dentro del builder (correrlas con verify.mjs).
