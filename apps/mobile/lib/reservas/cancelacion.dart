import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/dialogo_error.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import 'pantalla_confirmar_cambio.dart';
import 'reservas.dart';

/// Cancela [reserva] con los avisos de cada desenlace; la repite mientras la persona
/// elija reintentar tras un corte. Las pantallas que la usan ya pidieron confirmación.
///
/// - [marcar] pone la reserva que espera (o `null` al soltarla) en el estado de la pantalla.
/// - [alCancelar] quita la reserva de lo que se ve y suelta la espera.
/// - [recargar] vuelve a leer con avisos; [releer] sin ellos.
/// - [toleraCorte]: tras un corte, que la reserva ya esté cancelada es que el pedido
///   cortado la canceló.
Future<void> cancelarConAvisos(
  BuildContext context, {
  required Sesion sesion,
  required Reservas reservas,
  required Reserva reserva,
  required void Function(String? id) marcar,
  required void Function() alCancelar,
  required Future<void> Function() recargar,
  required Future<void> Function() releer,
  bool toleraCorte = false,
}) async {
  marcar(reserva.id);
  var huboCorte = false;
  while (context.mounted) {
    Object? fallo;
    try {
      try {
        await reservas.cancelar(reserva);
      } on ReservaCambiada {
        if (!(toleraCorte && huboCorte)) rethrow;
      }
      if (!context.mounted) return;
      alCancelar();
      await mostrarCancelada(context);
      if (context.mounted) await recargar();
      return;
    } on ReservaCambiada {
      if (!context.mounted) return;
      marcar(null);
      await mostrarCambioMientrasTanto(context);
      if (context.mounted) await recargar();
      return;
    } on SesionVencida {
      if (!context.mounted) return;
      marcar(null);
      await avisarSesionVencida(context, sesion);
      return;
    } on SinConexion catch (e) {
      huboCorte = true;
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    }
    if (!context.mounted) return;
    marcar(null);
    final otraVez = await preguntarReintento(context, fallo);
    if (!context.mounted) return;
    if (!otraVez) {
      // Si el corte llegó después de que el servidor la canceló, la lectura lo muestra.
      await releer();
      return;
    }
    marcar(reserva.id);
  }
}

/// Abre la grilla para cambiar [r] de horario y, al volver, avisa si se modificó.
/// Devuelve `false` si la pantalla ya no está.
Future<bool> abrirModificar(
  BuildContext context,
  Reserva r, {
  String ruta = '',
}) async {
  final resultado = await context.push<ResultadoDeModificar>(
    '/reservas/${r.id}/modificar$ruta',
    extra: r,
  );
  if (!context.mounted) return false;
  if (resultado == ResultadoDeModificar.modificada) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reserva modificada')));
  }
  return true;
}
