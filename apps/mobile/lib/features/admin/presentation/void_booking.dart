import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import '../../bookings/domain/booking_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../data/api_failures.dart';
import '../data/booking_history_api.dart';
import '../domain/booking_history_entry.dart';
import '../domain/history_filters.dart';
import '../domain/pending_panel_filters.dart';
import 'void_booking_dialog.dart';

/// How the attempt to void a booking ended.
enum VoidResult {
  /// The administrator gave up or the session expired: the booking did not change.
  nothing,

  /// The booking was voided.
  voided,

  /// The booking was no longer as it looked: the caller reads the list again.
  changed,
}

/// Asks for the reason, voids [booking] and reports how it ended. [submitting] notifies
/// while the request is in flight. If the connection or the server fail, the booking keeps
/// its state and a retry is offered. If the session expires, [filters] is left in
/// [pending] to be restored on signing in again.
Future<VoidResult> voidBooking(
  BuildContext context, {
  required BookingHistoryEntry booking,
  required BookingHistory history,
  required Session session,
  required HistoryFilters filters,
  required PendingPanelFilters pending,
  required ValueChanged<bool> submitting,
}) async {
  final reason = await askVoidReason(context, booking);
  if (reason == null || !context.mounted) return VoidResult.nothing;
  var hadCutoff = false;
  while (true) {
    Object? failure;
    var expired = false;
    var changed = false;
    submitting(true);
    try {
      await history.voidBooking(booking, reason);
    } on BookingChanged {
      // After a cutoff, "already voided" means the cut request voided it.
      changed = !hadCutoff;
    } on SessionExpired {
      expired = true;
    } on SinConexion catch (e) {
      hadCutoff = true;
      failure = e;
    } on ErrorDelServidor catch (e) {
      failure = e;
    } on BookingRejected {
      failure = const ErrorDelServidor(422);
    } finally {
      submitting(false);
    }
    if (!context.mounted) return VoidResult.nothing;
    if (changed) {
      await showChangedMeanwhile(context);
      return VoidResult.changed;
    }
    if (expired) {
      await avisarSesionVencida(
        context,
        session,
        antes: () => pending.save(filters),
      );
      return VoidResult.nothing;
    }
    final error = failure;
    if (error == null) {
      await showBookingVoided(context);
      return VoidResult.voided;
    }
    final retry = await askRetry(context, error);
    if (!retry || !context.mounted) return VoidResult.nothing;
  }
}
