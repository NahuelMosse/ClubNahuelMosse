import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';
import 'duration_picker.dart';
import 'slots_section.dart';

/// DURACIÓN: el selector de horas y lo que se puede elegir en la sede.
class DurationSection extends StatelessWidget {
  const DurationSection({
    super.key,
    required this.horas,
    required this.cierre,
    required this.alCambiar,
  });

  final int horas;

  /// La hora de cierre de la sede, tal como se muestra.
  final String cierre;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return SlotsSection(
      titulo: l.availabilityDuration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DurationSelector(horas: horas, alCambiar: alCambiar),
          const SizedBox(height: Spacing.s8),
          Text(
            l.availabilityDurationHint(cierre, maxHours, minHours),
            style: Texts.caption.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
