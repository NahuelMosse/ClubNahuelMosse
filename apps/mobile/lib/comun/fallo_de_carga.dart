import 'package:flutter/material.dart';

import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import 'dialogo_error.dart';

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
  if (vencida) {
    alVencer?.call();
    await mostrarSesionVencida(context);
    if (context.mounted) await cerrarSesion(context, sesion);
  } else if (error != null) {
    final quiereReintentar = await mostrarErrorDeRed(context, error);
    if (quiereReintentar && context.mounted) await reintentar();
  }
}
