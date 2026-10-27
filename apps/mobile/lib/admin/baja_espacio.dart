import 'package:flutter/material.dart';

import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import 'baja.dart';
import 'dialogos_de_baja.dart';

/// Confirma y da de baja [espacio] (CU-23). Con [volverAlListado] (se llegó desde la
/// edición), termina en el listado de espacios del panel.
Future<void> darDeBajaEspacio(
  BuildContext context, {
  required Espacio espacio,
  required Espacios espacios,
  required Sesion sesion,
  required ValueChanged<bool> enviando,
  bool volverAlListado = false,
}) => darDeBaja(
  context,
  confirmar: () => confirmarBajaDeEspacio(context, espacio.nombre),
  pedir: () async {
    try {
      await espacios.darDeBaja(espacio.id);
      return ResultadoDeBaja.hecha;
    } on EspacioNoDisponible {
      return ResultadoDeBaja.yaNoEsta;
    } on EspacioConReservas {
      return ResultadoDeBaja.conReservas;
    }
  },
  mostrarConReservas: () => mostrarEspacioConReservas(context),
  exito: 'El espacio fue dado de baja correctamente',
  avisarCambio: espacios.avisarCambio,
  sesion: sesion,
  enviando: enviando,
  volverA: volverAlListado ? '/admin/espacios' : null,
);
