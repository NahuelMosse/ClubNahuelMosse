import 'package:flutter/widgets.dart';

/// El error que un formulario muestra bajo un campo: el que dijo el servidor y, si no hay,
/// el de las reglas, pero sólo desde el primer intento de enviar o si la persona ya pasó por
/// el campo con algo escrito. Salir de un campo vacío no marca nada.
String? errorAMostrar({
  String? delServidor,
  required String? deRegla,
  required bool intentado,
  required bool tocado,
}) => delServidor ?? (intentado || tocado ? deRegla : null);

/// Lleva el foco al primer campo de [campos] que tiene error. Un selector, que no tiene
/// foco propio, no lo recibe.
void enfocarElPrimerFaltante(Iterable<(FocusNode?, String?)> campos) {
  for (final (foco, error) in campos) {
    if (error == null) continue;
    foco?.requestFocus();
    return;
  }
}
