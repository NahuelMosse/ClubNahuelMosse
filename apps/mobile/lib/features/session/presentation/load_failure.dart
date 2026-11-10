import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import 'account_card.dart';
import 'request_failure.dart';
import 'session.dart';

/// Avisa el fallo de una carga de pantalla: la sesión vencida cierra la sesión; un error
/// de red ofrece reintentar con [retry].
///
/// Tapada por otra pantalla no avisa: al volver, el listado ofrece REINTENTAR.
/// [onExpired] corre antes del aviso de sesión vencida; [onGiveUp], si la persona no
/// reintenta.
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

/// Avisa el fallo de un pedido: la sesión vencida cierra la sesión; un error de red
/// ofrece reintentar con [retry]. Sin fallo ni vencimiento no hace nada.
///
/// Con [onlyWhenFront], tapada por otra pantalla no avisa. [onExpired] corre antes del aviso
/// de sesión vencida; [onGiveUp], si la persona no reintenta y la pantalla sigue.
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

/// Avisa que la sesión venció y la cierra; [before] corre antes del aviso.
Future<void> notifySessionExpired(
  BuildContext context,
  Session session, {
  VoidCallback? before,
}) async {
  before?.call();
  await showSessionExpired(context);
  if (context.mounted) await signOut(context, session);
}

/// Avisa el error de red de [error] y devuelve si la persona eligió reintentar.
Future<bool> askRetry(BuildContext context, Object error) =>
    showNetworkError(context, error);
