import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
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
            etiqueta: l.availabilityLessHour,
            alTocar: horas > minHours ? () => alCambiar(horas - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l.bookingDuration(horas),
                textAlign: TextAlign.center,
                style: Texts.bodyStrong.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          RoundButton(
            icono: Icons.add_rounded,
            etiqueta: l.availabilityMoreHour,
            alTocar: horas < maxHours ? () => alCambiar(horas + 1) : null,
          ),
        ],
      ),
    );
  }
}
