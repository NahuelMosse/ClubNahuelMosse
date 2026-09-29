import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/dialogo_error.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';

/// Confirma y da de baja [sede], con el aviso al terminar. Con [volverAlListado] (se llegó
/// desde la edición), termina en el listado del panel; si la sede tiene reservas pendientes
/// o la red falla, se queda donde estaba. [enviando] avisa mientras el pedido está en camino.
Future<void> darDeBajaSede(
  BuildContext context, {
  required Sede sede,
  required Sedes sedes,
  required Sesion sesion,
  required ValueChanged<bool> enviando,
  bool volverAlListado = false,
}) async {
  final confirmada = await confirmarBajaDeSede(
    context,
    '${sede.nombre} · ${sede.direccion}. Sus espacios deportivos dejan de '
    'estar disponibles.',
  );
  if (!confirmada || !context.mounted) return;
  await _pedir(
    context,
    sede: sede,
    sedes: sedes,
    sesion: sesion,
    enviando: enviando,
    volverAlListado: volverAlListado,
    huboCorte: false,
  );
}

Future<void> _pedir(
  BuildContext context, {
  required Sede sede,
  required Sedes sedes,
  required Sesion sesion,
  required ValueChanged<bool> enviando,
  required bool volverAlListado,
  required bool huboCorte,
}) async {
  Object? fallo;
  var vencida = false;
  var yaNoEsta = false;
  var conReservas = false;
  var cortado = huboCorte;
  enviando(true);
  try {
    await sedes.darDeBaja(sede.id);
  } on SedeNoDisponible {
    yaNoEsta = true;
  } on SedeConReservas {
    conReservas = true;
  } on SesionVencida {
    vencida = true;
  } on SinConexion catch (e) {
    cortado = true;
    fallo = e;
  } on ErrorDelServidor catch (e) {
    fallo = e;
  } finally {
    enviando(false);
  }
  if (!context.mounted) return;
  // Después de un corte, que ya no esté es que el pedido cortado la dio de baja.
  if (yaNoEsta && huboCorte) {
    sedes.avisarCambio();
    yaNoEsta = false;
  }
  if (fallo == null && !vencida && !yaNoEsta && !conReservas) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La sede fue dada de baja correctamente')),
    );
    if (volverAlListado) context.go('/admin/sedes');
  } else if (yaNoEsta) {
    await mostrarCambioMientrasTanto(context);
    sedes.avisarCambio();
    if (volverAlListado && context.mounted) context.go('/admin/sedes');
  } else if (conReservas) {
    await mostrarSedeConReservas(context);
  } else if (vencida) {
    await mostrarSesionVencida(context);
    if (context.mounted) await cerrarSesion(context, sesion);
  } else if (fallo != null) {
    final reintentar = await mostrarErrorDeRed(context, fallo);
    if (reintentar && context.mounted) {
      await _pedir(
        context,
        sede: sede,
        sedes: sedes,
        sesion: sesion,
        enviando: enviando,
        volverAlListado: volverAlListado,
        huboCorte: cortado,
      );
    }
  }
}
