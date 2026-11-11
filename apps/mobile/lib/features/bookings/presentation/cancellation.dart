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

/// Cancels [booking] with the notices of each outcome; repeats it while the person
/// chooses to retry after an outage. The screens that use it already asked for
/// confirmation.
///
/// - [mark] puts the booking that is waiting (or `null` when released) in the state of
///   the screen.
/// - [onCancel] removes the booking from what is seen and releases the wait.
/// - [reload] reads again with notices; [reread] without them.
/// - [toleratesOutage]: after an outage, the booking already being cancelled means the
///   cut request cancelled it.
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
      // If the outage came after the server cancelled it, the read shows it.
      await reread();
      return;
    }
    mark(booking.id);
  }
}

/// Opens the grid to change the time of [r] and, on returning, reports whether it was
/// modified. Returns `false` if the screen is gone.
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
