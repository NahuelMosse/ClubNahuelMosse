import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';
import 'duration_picker.dart';
import 'slots_section.dart';

/// «DURACIÓN»: the hours selector and what can be chosen at the venue.
class DurationSection extends StatelessWidget {
  const DurationSection({
    super.key,
    required this.hours,
    required this.closing,
    required this.onChanged,
  });

  final int hours;

  /// The closing time of the venue, as it is shown.
  final String closing;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return SlotsSection(
      title: l.availabilityDuration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DurationSelector(hours: hours, onChanged: onChanged),
          const SizedBox(height: Spacing.s8),
          Text(
            l.availabilityDurationHint(closing, maxHours, minHours),
            style: Texts.caption.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
