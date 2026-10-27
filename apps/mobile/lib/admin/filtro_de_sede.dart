import 'package:flutter/material.dart';

import '../sedes/sede.dart';
import '../tema/tokens.dart';
import 'chip_de_filtro.dart';

/// Las sedes entre las que se puede filtrar; [alElegir] recibe la que se tocó.
class FiltroDeSede extends StatelessWidget {
  const FiltroDeSede({
    super.key,
    required this.sedes,
    required this.elegida,
    required this.alElegir,
  });

  final List<Sede> sedes;
  final String? elegida;
  final ValueChanged<Sede> alElegir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Medidas.s8,
      runSpacing: Medidas.s8,
      children: [
        for (final sede in sedes)
          ChipDeFiltro(
            texto: sede.nombre,
            alTocar: () => alElegir(sede),
            elegido: elegida == sede.id,
          ),
      ],
    );
  }
}
