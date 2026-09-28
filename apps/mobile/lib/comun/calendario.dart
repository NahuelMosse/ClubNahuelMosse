import 'package:flutter/material.dart';

/// El calendario para elegir una fecha de nacimiento: cualquier día anterior a hoy.
///
/// [propuesta] es la fecha en la que abre; si cae fuera del rango se acerca al borde, porque
/// el calendario de Material no abre con una fecha que no se puede elegir.
Future<DateTime?> elegirFechaDeNacimiento(
  BuildContext context,
  DateTime propuesta,
) {
  final hoy = DateTime.now();
  final ultima = DateTime(hoy.year, hoy.month, hoy.day - 1);
  final primera = propuesta.isBefore(DateTime(1900))
      ? propuesta
      : DateTime(1900);
  return showDatePicker(
    context: context,
    initialDate: propuesta.isAfter(ultima) ? ultima : propuesta,
    firstDate: primera,
    lastDate: ultima,
  );
}

/// El calendario de los [dias] que siguen desde [hoy], con [propuesta] marcada si cae
/// entre ellos.
Future<DateTime?> elegirDiaProximo(
  BuildContext context, {
  required DateTime hoy,
  required int dias,
  DateTime? propuesta,
}) {
  final primera = DateTime(hoy.year, hoy.month, hoy.day);
  final ultima = DateTime(hoy.year, hoy.month, hoy.day + dias - 1);
  final elegida = propuesta == null
      ? primera
      : DateTime(propuesta.year, propuesta.month, propuesta.day);
  return showDatePicker(
    context: context,
    initialDate: elegida.isBefore(primera) || elegida.isAfter(ultima)
        ? primera
        : elegida,
    firstDate: primera,
    lastDate: ultima,
  );
}
