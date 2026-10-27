import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Lo que ocupa el lugar de un botón mientras su acción está en camino: un indicador de
/// progreso del alto de un control que el lector de pantalla anuncia como [etiqueta].
class EnCurso extends StatelessWidget {
  const EnCurso(this.etiqueta, {super.key});

  final String etiqueta;

  @override
  Widget build(BuildContext context) => Semantics(
    label: etiqueta,
    excludeSemantics: true,
    child: const SizedBox(
      height: Medidas.altoControl,
      child: Center(child: CircularProgressIndicator()),
    ),
  );
}
