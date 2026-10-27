import 'package:flutter/material.dart';

import '../comun/selector.dart';

/// Un dato que se ve con el aspecto de un selector pero no se puede cambiar.
class CampoDeSoloLectura extends StatelessWidget {
  const CampoDeSoloLectura({
    super.key,
    required this.etiqueta,
    required this.etiquetaAccesible,
    required this.valor,
  });

  final String etiqueta;
  final String etiquetaAccesible;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return CampoSelector(
      etiqueta: etiqueta,
      etiquetaAccesible: etiquetaAccesible,
      valor: valor,
      placeholder: '',
      icono: Icons.expand_more_rounded,
      alTocar: null,
      soloLectura: true,
    );
  }
}
