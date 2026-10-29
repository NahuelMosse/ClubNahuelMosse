import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Los tres pasos de la reserva, con [actual] contado desde cero.
class BookingSteps extends StatelessWidget {
  const BookingSteps({super.key, required this.actual});

  final int actual;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final names = [l.bookingStepChoose, l.bookingStepConfirm, l.bookingStepDone];
    return Semantics(
      label: l.bookingStepLabel(names[actual], actual + 1, names.length),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < names.length; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.s8),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= actual ? p.accentBase : p.bgSurfaceRaised,
                      borderRadius: BorderRadius.circular(Spacing.radiusPill),
                    ),
                  ),
                  const SizedBox(height: Spacing.s8),
                  Text(
                    names[i],
                    textAlign: TextAlign.center,
                    style: Texts.caption.copyWith(
                      color: i == actual ? p.textPrimary : p.textMuted,
                      fontWeight: i == actual ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
