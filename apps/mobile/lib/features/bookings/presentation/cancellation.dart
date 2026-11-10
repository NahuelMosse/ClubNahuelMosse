// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/error_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../data/api_errors.dart';
import '../domain/booking.dart';
import '../domain/booking_exceptions.dart';
import 'bookings.dart';
import 'confirm_change_screen.dart';

/// Cancela [booking] con los avisos de cada desenlace; la repite mientras la persona
/// elija reintentar tras un corte. Las pantallas que la usan ya pidieron confirmación.
///
/// - [mark] pone la reserva que espera (o `null` al soltarla) en el estado de la pantalla.
/// - [onCancel] quita la reserva de lo que se ve y suelta la espera.
/// - [reload] vuelve a leer con avisos; [reread] sin ellos.
/// - [toleratesOutage]: tras un corte, que la reserva ya esté cancelada es que el pedido
///   cortado la canceló.
Future<void> cancelWithNotices(
  BuildContext context, {
  required Session session,
  required Bookings bookings,
  required Booking booking,
  required void Function(String? id) mark,
  required void Function() onCancel,
  required Future<void> Function() reload,
  required Future<void> Function() reread,
  bool toleratesOutage = false,
}) async {
  mark(booking.id);
  var hadOutage = false;
  while (context.mounted) {
    Object? failure;
    try {
      try {
        await bookings.cancel(booking);
      } on BookingChanged {
        if (!(toleratesOutage && hadOutage)) rethrow;
      }
      if (!context.mounted) return;
      onCancel();
      await showBookingCanceled(context);
      if (context.mounted) await reload();
      return;
    } on BookingChanged {
      if (!context.mounted) return;
      mark(null);
      await showChangedMeanwhile(context);
      if (context.mounted) await reload();
      return;
    } on SessionExpired {
      if (!context.mounted) return;
      mark(null);
      await notifySessionExpired(context, session);
      return;
    } on NoConnection catch (e) {
      hadOutage = true;
      failure = e;
    } on ServerError catch (e) {
      failure = e;
    }
    if (!context.mounted) return;
    mark(null);
    final again = await askRetry(context, failure);
    if (!context.mounted) return;
    if (!again) {
      // Si el corte llegó después de que el servidor la canceló, la lectura lo muestra.
      await reread();
      return;
    }
    mark(booking.id);
  }
}

/// Abre la grilla para cambiar [r] de horario y, al volver, avisa si se modificó.
/// Devuelve `false` si la pantalla ya no está.
Future<bool> openModify(
  BuildContext context,
  Booking r, {
  String route = '',
}) async {
  final result = await context.push<ModifyResult>(
    '/bookings/${r.id}/modify$route',
    extra: r,
  );
  if (!context.mounted) return false;
  if (result == ModifyResult.modified) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).bookingModified)),
    );
  }
  return true;
}
