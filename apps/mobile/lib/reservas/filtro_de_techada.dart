import 'package:flutter/material.dart';

import '../comun/chip_elegible.dart';
import '../tema/tokens.dart';

/// Los chips Todas / Al aire libre / Techada con cuántas canchas trae cada uno.
class FiltroDeTechada extends StatelessWidget {
  const FiltroDeTechada({
    super.key,
    required this.total,
    required this.aireLibre,
    required this.elegida,
    required this.alElegir,
  });

  final int total;
  final int aireLibre;

  /// `null` es «Todas».
  final bool? elegida;
  final ValueChanged<bool?> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (valor, cuantas) in [
            (null, total),
            (false, aireLibre),
            (true, total - aireLibre),
          ]) ...[
            ChipElegible(
              texto:
                  '${switch (valor) {
                    null => 'Todas',
                    false => 'Al aire libre',
                    true => 'Techada',
                  }} ($cuantas)',
              elegido: elegida == valor,
              alTocar: cuantas == 0 ? null : () => alElegir(valor),
              alto: Medidas.s48,
              conBorde: true,
              tintaSinTocar: p.textMuted,
            ),
            const SizedBox(width: Medidas.s8),
          ],
        ],
      ),
    );
  }
}
