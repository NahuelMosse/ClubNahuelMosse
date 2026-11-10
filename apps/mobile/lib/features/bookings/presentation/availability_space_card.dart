// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/space_texts.dart';
import 'selectable_frame.dart';

class AvailabilitySpaceCard extends StatelessWidget {
  const AvailabilitySpaceCard({
    super.key,
    required this.space,
    required this.chosen,
    required this.onTap,
  });

  final Space space;
  final bool chosen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final condition = conditionText(l, space);
    return SelectableFrame(
      label: l.availabilityCourtLabel(condition, space.number),
      selected: chosen,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.availabilityCourt(space.number),
              style: Texts.bodyStrong.copyWith(
                color: chosen ? p.accentOn : p.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              condition,
              style: Texts.caption.copyWith(
                color: chosen ? p.accentOn : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
