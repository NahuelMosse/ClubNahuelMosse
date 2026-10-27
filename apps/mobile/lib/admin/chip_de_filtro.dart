import 'package:flutter/material.dart';

import '../comun/chip_elegible.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Una opción del panel de filtros: se prende y se apaga al tocarla.
class ChipDeFiltro extends StatelessWidget {
  const ChipDeFiltro({
    super.key,
    required this.texto,
    required this.alTocar,
    required this.elegido,
  });

  final String texto;
  final VoidCallback alTocar;
  final bool elegido;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ChipElegible(
      texto: texto,
      elegido: elegido,
      alTocar: alTocar,
      estilo: Textos.cuerpo,
      relleno: const EdgeInsets.symmetric(
        horizontal: Medidas.s16,
        vertical: Medidas.s8,
      ),
      fondoApagado: p.bgSurface,
    );
  }
}
