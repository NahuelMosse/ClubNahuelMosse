import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/error_dialog.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../data/api_errors.dart';
import '../domain/booking.dart';
import '../domain/booking_exceptions.dart';
import 'bookings.dart';
import 'confirm_change_screen.dart';

/// Cancela [reserva] con los avisos de cada desenlace; la repite mientras la persona
/// elija reintentar tras un corte. Las pantallas que la usan ya pidieron confirmación.
///
/// - [marcar] pone la reserva que espera (o `null` al soltarla) en el estado de la pantalla.
/// - [alCancelar] quita la reserva de lo que se ve y suelta la espera.
/// - [recargar] vuelve a leer con avisos; [releer] sin ellos.
/// - [toleraCorte]: tras un corte, que la reserva ya esté cancelada es que el pedido
///   cortado la canceló.
Future<void> cancelWithNotices(
  BuildContext context, {
  required Session sesion,
  required Bookings reservas,
  required Booking reserva,
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
        await reservas.cancel(reserva);
      } on BookingChanged {
        if (!(toleraCorte && huboCorte)) rethrow;
      }
      if (!context.mounted) return;
      alCancelar();
      await showBookingCanceled(context);
      if (context.mounted) await recargar();
      return;
    } on BookingChanged {
      if (!context.mounted) return;
      marcar(null);
      await showChangedMeanwhile(context);
      if (context.mounted) await recargar();
      return;
    } on SessionExpired {
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
    final otraVez = await askRetry(context, fallo);
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
  Booking r, {
  String ruta = '',
}) async {
  final resultado = await context.push<ModifyResult>(
    '/reservas/${r.id}/modificar$ruta',
    extra: r,
  );
  if (!context.mounted) return false;
  if (resultado == ModifyResult.modificada) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reserva modificada')));
  }
  return true;
}
