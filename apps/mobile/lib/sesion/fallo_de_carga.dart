import 'package:flutter/material.dart';

import '../comun/dialogo_error.dart';
import 'sesion.dart';
import 'tarjeta_cuenta.dart';

/// Avisa el fallo de una carga de pantalla: la sesión vencida cierra la sesión; un error
/// de red ofrece reintentar con [reintentar].
///
/// Tapada por otra pantalla no avisa: al volver, el listado ofrece REINTENTAR.
/// [alVencer] corre antes del aviso de sesión vencida.
Future<void> avisarFalloDeCarga(
  BuildContext context, {
  required Sesion sesion,
  required bool vencida,
  required Object? error,
  required Future<void> Function() reintentar,
  VoidCallback? alVencer,
}) async {
  if (ModalRoute.of(context)?.isCurrent == false) return;
  if (vencida) alVencer?.call();
  await avisarFalloDeEnvio(
    context,
    sesion: sesion,
    vencida: vencida,
    error: error,
    reintentar: reintentar,
  );
}

/// Avisa el fallo de un pedido: la sesión vencida cierra la sesión; un error de red
/// ofrece reintentar con [reintentar]. Sin fallo ni vencimiento no hace nada.
Future<void> avisarFalloDeEnvio(
  BuildContext context, {
  required Sesion sesion,
  required bool vencida,
  required Object? error,
  required Future<void> Function() reintentar,
}) async {
  if (vencida) {
    await mostrarSesionVencida(context);
    if (context.mounted) await cerrarSesion(context, sesion);
  } else if (error != null) {
    final quiereReintentar = await mostrarErrorDeRed(context, error);
    if (quiereReintentar && context.mounted) await reintentar();
  }
}
