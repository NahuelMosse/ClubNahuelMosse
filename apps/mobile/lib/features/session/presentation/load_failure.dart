import 'package:flutter/material.dart';

import '../../../common/error_dialog.dart';
import 'account_card.dart';
import 'session.dart';

/// Avisa el fallo de una carga de pantalla: la sesión vencida cierra la sesión; un error
/// de red ofrece reintentar con [reintentar].
///
/// Tapada por otra pantalla no avisa: al volver, el listado ofrece REINTENTAR.
/// [alVencer] corre antes del aviso de sesión vencida; [alNoReintentar], si la persona no
/// reintenta.
Future<void> avisarFalloDeCarga(
  BuildContext context, {
  required Session session,
  required bool expired,
  required Object? error,
  required Future<void> Function() reintentar,
  VoidCallback? alVencer,
  VoidCallback? alNoReintentar,
}) => avisarFalloDeEnvio(
  context,
  session: session,
  expired: expired,
  error: error,
  reintentar: reintentar,
  soloAlFrente: true,
  alVencer: alVencer,
  alNoReintentar: alNoReintentar,
);

/// Avisa el fallo de un pedido: la sesión vencida cierra la sesión; un error de red
/// ofrece reintentar con [reintentar]. Sin fallo ni vencimiento no hace nada.
///
/// Con [soloAlFrente], tapada por otra pantalla no avisa. [alVencer] corre antes del aviso
/// de sesión vencida; [alNoReintentar], si la persona no reintenta y la pantalla sigue.
Future<void> avisarFalloDeEnvio(
  BuildContext context, {
  required Session session,
  required bool expired,
  required Object? error,
  required Future<void> Function() reintentar,
  bool soloAlFrente = false,
  VoidCallback? alVencer,
  VoidCallback? alNoReintentar,
}) async {
  if (soloAlFrente && ModalRoute.of(context)?.isCurrent == false) return;
  if (expired) {
    await avisarSesionVencida(context, session, antes: alVencer);
  } else if (error != null) {
    if (await askRetry(context, error)) {
      if (context.mounted) await reintentar();
    } else if (context.mounted) {
      alNoReintentar?.call();
    }
  }
}

/// Avisa que la sesión venció y la cierra; [antes] corre antes del aviso.
Future<void> avisarSesionVencida(
  BuildContext context,
  Session session, {
  VoidCallback? antes,
}) async {
  antes?.call();
  await showSessionExpired(context);
  if (context.mounted) await signOut(context, session);
}

/// Avisa el error de red de [error] y devuelve si la persona eligió reintentar.
Future<bool> askRetry(BuildContext context, Object error) =>
    showNetworkError(context, error);
