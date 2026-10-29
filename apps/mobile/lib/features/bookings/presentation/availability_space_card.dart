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
    required this.cancha,
    required this.elegida,
    required this.alTocar,
  });

  final Space cancha;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final condition = conditionText(l, cancha);
    return SelectableFrame(
      etiqueta: l.availabilityCourtLabel(condition, cancha.number),
      elegido: elegida,
      alTocar: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.availabilityCourt(cancha.number),
              style: Texts.bodyStrong.copyWith(
                color: elegida ? p.accentOn : p.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              condition,
              style: Texts.caption.copyWith(
                color: elegida ? p.accentOn : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
