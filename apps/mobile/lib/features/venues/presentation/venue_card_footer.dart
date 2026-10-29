import 'package:flutter/material.dart';

import '../../../common/label.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Los deportes de la sede y «Ver canchas».
class VenueCardFooter extends StatelessWidget {
  const VenueCardFooter({super.key, required this.sports});

  final List<String> sports;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Spacing.s4,
              runSpacing: Spacing.s4,
              children: [for (final d in sports) AppLabel(text: d)],
            ),
          ),
          const SizedBox(width: Spacing.s8),
          Text(
            AppLocalizations.of(context).venueSeeCourts,
            style: Texts.bodyStrong.copyWith(color: p.accentInk),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: p.accentInk),
        ],
      ),
    );
  }
}
