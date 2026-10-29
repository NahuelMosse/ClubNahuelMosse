// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/label.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/space_texts.dart';

/// Condición e iluminación a la izquierda y el precio a la derecha; con el texto grande el
/// precio baja debajo de las etiquetas en vez de cortarse.
class LabelsAndPrice extends StatelessWidget {
  const LabelsAndPrice({super.key, required this.space, required this.price});

  final Space space;
  final String price;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final labels = Wrap(
      spacing: Spacing.s4,
      runSpacing: Spacing.s4,
      children: [
        AppLabel(
          text: conditionText(l, space),
          icon: space.covered ? Icons.roofing_rounded : Icons.wb_sunny_outlined,
        ),
        AppLabel(
          text: lightingText(l, space),
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
        Text(l.spacePerHourBadge, style: Texts.overline.copyWith(color: p.textMuted)),
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
