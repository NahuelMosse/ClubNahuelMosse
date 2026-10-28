import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
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
    return SelectableFrame(
      etiqueta: 'Cancha ${cancha.number}, ${cancha.condition}',
      elegido: elegida,
      alTocar: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancha ${cancha.number}',
              style: Texts.bodyStrong.copyWith(
                color: elegida ? p.accentOn : p.textPrimary,
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              cancha.condition,
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
