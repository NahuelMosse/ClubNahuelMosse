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
    required this.hours,
    required this.onChanged,
  });

  final int hours;
  final ValueChanged<int> onChanged;

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
            icon: Icons.remove_rounded,
            label: l.availabilityLessHour,
            onTap: hours > minHours ? () => onChanged(hours - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                l.bookingDuration(hours),
                textAlign: TextAlign.center,
                style: Texts.bodyStrong.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          RoundButton(
            icon: Icons.add_rounded,
            label: l.availabilityMoreHour,
            onTap: hours < maxHours ? () => onChanged(hours + 1) : null,
          ),
        ],
      ),
    );
  }
}
