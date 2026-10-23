# Handoff · REV-06 S5 · duplicación de la app

Alcance: NO tocar `apps/api/app` (lo extrae REV-01). Sólo `apps/mobile/lib` bajo 3 % y las líneas `declared · K4` del Log.

## Hecho (commiteado)
- 5,64 % -> 4,75 % (837 de 17617 líneas, 71 clones). Meta: menos de ~528 líneas duplicadas (apuntar a ~480): faltan ~310.
- `comun/campo_texto.dart`: widget `MensajeDeCampo` (usado por `selector.dart`).
- `comun/fallo_de_carga.dart`: `avisarFalloDeCarga(context, sesion, vencida, error, reintentar, alVencer)`.
- `admin/listado_admin.dart`: `EncabezadoAdmin`, `PlantillaListadoAdmin`, `cabeceraDeListadoAdmin`, `TarjetaAdmin`; usados por espacios_admin, sedes_admin y panel_admin (encabezado + fallo).
- `flutter analyze lib` sin problemas; `flutter test test/admin` verde (test/comun no existe). T4 de card.md ya lista estos archivos.

## Hecho en la segunda tanda (4,75 % -> 4,09 %, 720 líneas; faltan ~240 para ~480)
- `comun/marco_de_tarjeta.dart` (`MarcoDeTarjeta`), usado en pantalla_sede y reserva_confirmada.
- confirmar_reserva.dart: `EsqueletoDeConfirmacion`, `TarjetaDeEleccion`, `avisarReservaRechazada`; confirmar_cambio los usa.
- `fallo_de_carga.dart` pasó a `sesion/` (comun sólo puede importar api y tema); inicio y mis_reservas lo usan.
- `flutter analyze lib` limpio; verdes: arquitectura, reservar, modificar_reserva, mis_reservas, inicio. Corrida completa sin capturas: sólo fallaban las 2 de arquitectura (ya arregladas).
- Siguiente planeado: `MarcoDeDialogo`/`CirculoDeIcono` públicos en dialogo_error.dart para anular y `_ConfirmarBaja` (mi_perfil); `MensajeDeCampo` en dialogo_anular_reserva (170-186); luego los ítems 3-5 de abajo.

## Pendiente, por ahorro (los 1 y 2 están hechos)
1. `reservas/pantalla_confirmar_cambio.dart` vs `pantalla_confirmar_reserva.dart` (~80 líneas): extraer en confirmar_reserva.dart un `EsqueletoDeConfirmacion` (PopScope+Scaffold+BarraSuperior+pie con BotonPrimario/BotonContorno+ListView con PasosDeReserva), `TarjetaDeEleccion(eleccion, filas)` (foto + filas + Divider + FilaDeTotal) y un helper del snackbar de `ReservaRechazada`.
2. Marco de tarjeta repetido (`Container clip antiAlias, bgSurfaceRaised, radioLg, borderDefault`, 20 usos): un `MarcoDeTarjeta` en `comun/` resuelve sede.dart:621, cambio:172, etc.
3. `inicio/pantalla_inicio.dart` vs `reservas/pantalla_mis_reservas.dart` (26, 21, 15, 13, 11, 11, 10) y vs `usuarios/pantalla_mi_perfil.dart` (11).
4. `sesion/pantalla_nueva_contrasena.dart` vs `usuarios/pantalla_cambiar_contrasena.dart` (20, 15) y vs `pantalla_mi_perfil.dart` (14, 10), `pantalla_recuperar_contrasena` (10).
5. `admin/pantalla_alta_espacio.dart` / `pantalla_editar_espacio.dart` / `pantalla_formulario_sede.dart` (16, 15, 17, 11, 20, y vs sedes/notificaciones ~15 c/u), `admin/pantalla_detalle_reserva.dart` vs panel_admin/tarjeta_reserva (20, 9, 12, 21), `admin/historial_reservas.dart` vs `reservas/reservas.dart` (15, 16, 15, 7), `admin/dialogo_anular_reserva.dart` vs `dialogo_error.dart` / `pantalla_mi_perfil.dart` (24, 10), `estado_reserva_chip.dart` vs mis_reservas (18), `comun/boton.dart` vs `barra_inferior.dart` (14), `app.dart` (12), `sesion.dart` internos.
6. Cada archivo de producción tocado va a la línea T4 de card.md con `(presentation)`.
7. Líneas `declared · K4` en el Log, una por clon con un lado test congelado (lista: `/tmp/gate-final-rev06.log`, líneas `required: failed: K4` de `tests/`): `- L<n> · declared · K4 · <archivo>:<líneas> · test congelado con tags, no se puede editar`. No hechas.
8. Al final: una línea de Log con porcentajes antes/después (5,64 % -> X %), `flutter test` completo incluido `test/capturas` en background (PATH="/d/projects/flutter/bin:$PATH", log `/tmp/rev06-dup2-<n>.log`). No correr verify ni push.

## Medir
`npx -y jscpd@4 --silent --reporters json --output /tmp/rev06-dup2-jm apps/mobile/lib` y `node D:/Temp/rev06-list.cjs D:/Temp/rev06-dup2-jm/jscpd-report.json` (en `D:\Temp\rev06-dup2-jm`). `--threshold` solo hace fallar con exit; con `--silent` el reporte de consola no sale en este equipo.
