import 'package:flutter/material.dart';

import '../../../common/selectable_chip.dart';
import '../../../theme/tokens.dart';

/// Los chips Todas / Al aire libre / Techada con cuántas canchas trae cada uno.
class CoveredFilter extends StatelessWidget {
  const CoveredFilter({
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
    final p = context.palette;
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
            SelectableChip(
              text:
                  '${switch (valor) {
                    null => 'Todas',
                    false => 'Al aire libre',
                    true => 'Techada',
                  }} ($cuantas)',
              selected: elegida == valor,
              onTap: cuantas == 0 ? null : () => alElegir(valor),
              minHeight: Spacing.s48,
              bordered: true,
              disabledInk: p.textMuted,
            ),
            const SizedBox(width: Spacing.s8),
          ],
        ],
      ),
    );
  }
}
