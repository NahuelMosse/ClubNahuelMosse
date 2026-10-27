import 'package:flutter/material.dart';

import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'chip_de_filtro.dart';

/// Los deportes del catálogo entre los que se puede filtrar; [alElegir] recibe el que se tocó.
class FiltroDeDeporte extends StatelessWidget {
  const FiltroDeDeporte({
    super.key,
    required this.deportes,
    required this.elegido,
    required this.alElegir,
  });

  final List<Deporte> deportes;
  final String? elegido;
  final ValueChanged<Deporte> alElegir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Medidas.s8,
      runSpacing: Medidas.s8,
      children: [
        for (final deporte in deportes)
          ChipDeFiltro(
            texto: deporte.nombre,
            alTocar: () => alElegir(deporte),
            elegido: elegido == deporte.clave,
          ),
      ],
    );
  }
}
