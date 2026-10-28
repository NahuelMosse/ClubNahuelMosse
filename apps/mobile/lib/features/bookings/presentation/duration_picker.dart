import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';
import 'round_button.dart';

/// `Stepper-Duracion`: una hora menos, la duración y una hora más.
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.horas,
    required this.alCambiar,
  });

  final int horas;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: Spacing.controlHeight,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
      ),
      child: Row(
        children: [
          RoundButton(
            icono: Icons.remove_rounded,
            etiqueta: 'Una hora menos',
            alTocar: horas > minHours ? () => alCambiar(horas - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                duration(horas),
                textAlign: TextAlign.center,
                style: Texts.bodyStrong.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          RoundButton(
            icono: Icons.add_rounded,
            etiqueta: 'Una hora más',
            alTocar: horas < maxHours ? () => alCambiar(horas + 1) : null,
          ),
        ],
      ),
    );
  }
}
