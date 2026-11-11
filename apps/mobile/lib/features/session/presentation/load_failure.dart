import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import 'account_card.dart';
import 'request_failure.dart';
import 'session.dart';

/// Reports the failure of a screen load: an expired session signs out; a network error
/// offers to retry with [retry].
///
/// Covered by another screen it does not report: on return, the list offers «REINTENTAR».
/// [onExpired] runs before the expired-session notice; [onGiveUp], if the person does not
/// retry.
Future<void> notifyLoadFailure(
  BuildContext context, {
  required Session session,
  required bool expired,
  required Object? error,
  required Future<void> Function() retry,
  VoidCallback? onExpired,
  VoidCallback? onGiveUp,
}) => notifySendFailure(
  context,
  session: session,
  expired: expired,
  error: error,
  retry: retry,
  onlyWhenFront: true,
  onExpired: onExpired,
  onGiveUp: onGiveUp,
);

/// Runs the screen load [load]; when it ends in an expired session or a network failure,
/// calls [onFailed] so the screen stops waiting and then gives the load-failure notice,
/// which retries with [retry].
Future<void> loadOrNotify(
  BuildContext context, {
  required Session session,
  required Future<void> Function() load,
  required VoidCallback onFailed,
  required Future<void> Function() retry,
}) async {
  final failure = await captureRequestFailure(load);
  if (failure.expired == false && failure.error == null) return;
  if (!context.mounted) return;
  onFailed();
  await notifyLoadFailure(
    context,
    session: session,
    expired: failure.expired,
    error: failure.error,
    retry: retry,
  );
}

/// Reports the failure of a request: an expired session signs out; a network error offers
/// to retry with [retry]. Without a failure or expiry it does nothing.
///
/// With [onlyWhenFront], covered by another screen it does not report. [onExpired] runs
/// before the expired-session notice; [onGiveUp], if the person does not retry and the
/// screen remains.
Future<void> notifySendFailure(
  BuildContext context, {
  required Session session,
  required bool expired,
  required Object? error,
  required Future<void> Function() retry,
  bool onlyWhenFront = false,
  VoidCallback? onExpired,
  VoidCallback? onGiveUp,
}) async {
  if (onlyWhenFront && ModalRoute.of(context)?.isCurrent == false) return;
  if (expired) {
    await notifySessionExpired(context, session, before: onExpired);
  } else if (error != null) {
    if (await askRetry(context, error)) {
      if (context.mounted) await retry();
    } else if (context.mounted) {
      onGiveUp?.call();
    }
  }
}

/// Reports that the session expired and closes it; [before] runs before the notice.
Future<void> notifySessionExpired(
  BuildContext context,
  Session session, {
  VoidCallback? before,
}) async {
  before?.call();
  await showSessionExpired(context);
  if (context.mounted) await signOut(context, session);
}

/// Reports the network error of [error] and returns whether the person chose to retry.
Future<bool> askRetry(BuildContext context, Object error) =>
    showNetworkError(context, error);
