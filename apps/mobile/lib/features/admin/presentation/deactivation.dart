// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/error_dialog.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../data/api_failures.dart';

/// How the deactivation request ended in the API.
enum DeactivationResult {
  done,

  /// Another session had already deactivated it.
  gone,

  /// It has bookings that have not ended yet (decision 5).
  withBookings,
}

/// Confirms and deactivates a venue or a space, with [success] in a notice at the end.
/// With [returnTo] (it was reached from editing), it ends at that list; if it has pending
/// bookings or the network fails, it stays where it was. [submitting] notifies while the
/// request is in flight. [notifyChange] makes the list be read again.
Future<void> deactivate(
  BuildContext context, {
  required Future<bool> Function() confirm,
  required Future<DeactivationResult> Function() request,
  required Future<void> Function() showWithBookings,
  required String success,
  required VoidCallback notifyChange,
  required Session session,
  required ValueChanged<bool> submitting,
  String? returnTo,
}) async {
  if (!await confirm() || !context.mounted) return;
  var hadCutoff = false;
  while (true) {
    DeactivationResult? result;
    Object? failure;
    var expired = false;
    submitting(true);
    try {
      result = await request();
    } on SessionExpired {
      expired = true;
    } on FalloDeRed catch (e) {
      failure = e;
    } finally {
      submitting(false);
    }
    if (!context.mounted) return;
    // After a cutoff, "it is gone" means the cut request deactivated it.
    if (result == DeactivationResult.gone && hadCutoff) {
      result = DeactivationResult.done;
      notifyChange();
    }
    switch (result) {
      case DeactivationResult.done:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
        if (returnTo case final route?) context.go(route);
        return;
      case DeactivationResult.gone:
        await showChangedMeanwhile(context);
        notifyChange();
        if (returnTo case final route? when context.mounted) context.go(route);
        return;
      case DeactivationResult.withBookings:
        await showWithBookings();
        return;
      case null:
        if (expired) {
          await avisarSesionVencida(context, session);
          return;
        }
        if (failure == null) return;
        if (!await askRetry(context, failure) || !context.mounted) {
          return;
        }
        if (failure is SinConexion) hadCutoff = true;
    }
  }
}
