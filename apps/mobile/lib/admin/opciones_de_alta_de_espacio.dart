import 'package:flutter/material.dart';

import '../comun/selector.dart';
import '../espacios/espacio.dart';
import '../sedes/sede.dart';
import 'formulario_de_alta_de_espacio.dart';

/// Pide elegir la sede del espacio entre las activas; `null` si se cerró sin elegir.
Future<Sede?> elegirSedeDeAlta(
  BuildContext context,
  FormularioDeAltaDeEspacio formulario,
) {
  final opciones = formulario.opcionesDeSede ?? const <Sede>[];
  return elegirOpcion<Sede>(
    context,
    titulo: 'Sede',
    opciones: [for (final s in opciones) (s, s.nombre)],
    elegida: formulario.sede,
  );
}

/// Pide elegir el deporte del espacio; `null` si se cerró sin elegir o aún no hay catálogo.
Future<Deporte?> elegirDeporteDeAlta(
  BuildContext context,
  FormularioDeAltaDeEspacio formulario,
) async {
  final catalogo = formulario.catalogo;
  if (catalogo == null) return null;
  return elegirOpcion<Deporte>(
    context,
    titulo: 'Deporte',
    opciones: [for (final d in catalogo.deportes) (d, d.nombre)],
    elegida: formulario.deporte,
  );
}

/// Pide elegir el tipo de cancha entre los del deporte elegido; `null` si se cerró sin
/// elegir o aún no hay deporte.
Future<TipoDeCancha?> elegirTipoDeAlta(
  BuildContext context,
  FormularioDeAltaDeEspacio formulario,
) async {
  final deporte = formulario.deporte;
  if (deporte == null) return null;
  return elegirOpcion<TipoDeCancha>(
    context,
    titulo: 'Tipo',
    opciones: [for (final t in deporte.tipos) (t, t.nombre)],
    elegida: formulario.tipo,
  );
}
