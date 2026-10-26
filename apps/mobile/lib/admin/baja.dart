import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/dialogo_error.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';

/// Cómo terminó el pedido de baja en la API.
enum ResultadoDeBaja {
  hecha,

  /// Otra sesión ya la había dado de baja.
  yaNoEsta,

  /// Tiene reservas que todavía no terminaron (decisión 5).
  conReservas,
}

/// Confirma y da de baja una sede o un espacio, con [exito] en un aviso al terminar. Con
/// [volverA] (se llegó desde la edición), termina en ese listado; si tiene reservas
/// pendientes o la red falla, se queda donde estaba. [enviando] avisa mientras el pedido está
/// en camino. [avisarCambio] hace que el listado se vuelva a leer.
Future<void> darDeBaja(
  BuildContext context, {
  required Future<bool> Function() confirmar,
  required Future<ResultadoDeBaja> Function() pedir,
  required Future<void> Function() mostrarConReservas,
  required String exito,
  required VoidCallback avisarCambio,
  required Sesion sesion,
  required ValueChanged<bool> enviando,
  String? volverA,
}) async {
  if (!await confirmar() || !context.mounted) return;
  var huboCorte = false;
  while (true) {
    ResultadoDeBaja? resultado;
    Object? fallo;
    var vencida = false;
    enviando(true);
    try {
      resultado = await pedir();
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
      fallo = e;
    } finally {
      enviando(false);
    }
    if (!context.mounted) return;
    // Después de un corte, que ya no esté es que el pedido cortado la dio de baja.
    if (resultado == ResultadoDeBaja.yaNoEsta && huboCorte) {
      resultado = ResultadoDeBaja.hecha;
      avisarCambio();
    }
    switch (resultado) {
      case ResultadoDeBaja.hecha:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exito)));
        if (volverA case final ruta?) context.go(ruta);
        return;
      case ResultadoDeBaja.yaNoEsta:
        await mostrarCambioMientrasTanto(context);
        avisarCambio();
        if (volverA case final ruta? when context.mounted) context.go(ruta);
        return;
      case ResultadoDeBaja.conReservas:
        await mostrarConReservas();
        return;
      case null:
        if (vencida) {
          await avisarSesionVencida(context, sesion);
          return;
        }
        if (fallo == null) return;
        if (!await preguntarReintento(context, fallo) || !context.mounted) {
          return;
        }
        if (fallo is SinConexion) huboCorte = true;
    }
  }
}
