import 'package:flutter/material.dart';

import '../../../common/label.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';

/// Condición e iluminación a la izquierda y el precio a la derecha; con el texto grande el
/// precio baja debajo de las etiquetas en vez de cortarse.
class LabelsAndPrice extends StatelessWidget {
  const LabelsAndPrice({super.key, required this.space, required this.price});

  final Space space;
  final String price;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final labels = Wrap(
      spacing: Spacing.s4,
      runSpacing: Spacing.s4,
      children: [
        AppLabel(
          text: space.condition,
          icon: space.covered ? Icons.roofing_rounded : Icons.wb_sunny_outlined,
        ),
        AppLabel(
          text: space.lighting,
          icon: space.lit
              ? Icons.lightbulb_outline_rounded
              : Icons.nightlight_outlined,
        ),
      ],
    );
    final amount = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(price, style: Texts.h2.copyWith(color: p.accentInk)),
        Text('/ HORA', style: Texts.overline.copyWith(color: p.textMuted)),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          labels,
          const SizedBox(height: Spacing.s8),
          Align(alignment: Alignment.centerRight, child: amount),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: labels),
        const SizedBox(width: Spacing.s8),
        amount,
      ],
    );
  }
}
