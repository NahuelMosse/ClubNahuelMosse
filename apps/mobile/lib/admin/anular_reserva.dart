import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/dialogo_error.dart';
import '../reservas/reservas.dart' show ReservaCambiada, ReservaRechazada;
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import 'dialogo_anular_reserva.dart';
import 'historial_reservas.dart';

/// Cómo terminó el intento de anular una reserva.
enum ResultadoDeAnulacion {
  /// El administrador desistió o la sesión venció: la reserva no cambió.
  nada,

  /// La reserva quedó anulada.
  anulada,

  /// La reserva ya no estaba como se la veía: quien llama vuelve a leer el listado.
  cambio,
}

/// Pide el motivo, anula [reserva] y avisa cómo terminó. [enviando] avisa mientras el pedido
/// está en camino. Si la conexión o el servidor fallan, la reserva conserva su estado y se
/// ofrece reintentar. Si la sesión vence, [filtros] queda en [pendientes] para restaurarse al
/// volver a entrar.
Future<ResultadoDeAnulacion> anularReserva(
  BuildContext context, {
  required ReservaHistorial reserva,
  required HistorialDeReservas historial,
  required Sesion sesion,
  required FiltrosDeHistorial filtros,
  required FiltrosDePanelPendientes pendientes,
  required ValueChanged<bool> enviando,
}) async {
  final motivo = await pedirMotivoDeAnulacion(context, reserva);
  if (motivo == null || !context.mounted) return ResultadoDeAnulacion.nada;
  while (true) {
    Object? fallo;
    var vencida = false;
    var cambio = false;
    enviando(true);
    try {
      await historial.anular(reserva, motivo);
    } on ReservaCambiada {
      cambio = true;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } on ReservaRechazada {
      fallo = const ErrorDelServidor(422);
    } finally {
      enviando(false);
    }
    if (!context.mounted) return ResultadoDeAnulacion.nada;
    if (cambio) {
      await mostrarCambioMientrasTanto(context);
      return ResultadoDeAnulacion.cambio;
    }
    if (vencida) {
      pendientes.guardar(filtros);
      await mostrarSesionVencida(context);
      if (context.mounted) await cerrarSesion(context, sesion);
      return ResultadoDeAnulacion.nada;
    }
    final error = fallo;
    if (error == null) {
      await mostrarReservaAnulada(context);
      return ResultadoDeAnulacion.anulada;
    }
    final reintentar = await mostrarErrorDeRed(context, error);
    if (!reintentar || !context.mounted) return ResultadoDeAnulacion.nada;
  }
}
