import 'package:flutter/material.dart';

import '../comun/dialogo_error.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import 'baja.dart';

/// Confirma y da de baja [sede] y sus espacios (CU-19). Con [volverAlListado] (se llegó
/// desde la edición), termina en el listado de sedes del panel.
Future<void> darDeBajaSede(
  BuildContext context, {
  required Sede sede,
  required Sedes sedes,
  required Sesion sesion,
  required ValueChanged<bool> enviando,
  bool volverAlListado = false,
}) => darDeBaja(
  context,
  confirmar: () => confirmarBajaDeSede(
    context,
    '${sede.nombre} · ${sede.direccion}. Sus espacios deportivos dejan de '
    'estar disponibles.',
  ),
  pedir: () async {
    try {
      await sedes.darDeBaja(sede.id);
      return ResultadoDeBaja.hecha;
    } on SedeNoDisponible {
      return ResultadoDeBaja.yaNoEsta;
    } on SedeConReservas {
      return ResultadoDeBaja.conReservas;
    }
  },
  mostrarConReservas: () => mostrarSedeConReservas(context),
  exito: 'La sede fue dada de baja correctamente',
  avisarCambio: sedes.avisarCambio,
  sesion: sesion,
  enviando: enviando,
  volverA: volverAlListado ? '/admin/sedes' : null,
);
