import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';

/// Los tres pasos de la reserva, con [actual] contado desde cero.
class BookingSteps extends StatelessWidget {
  const BookingSteps({super.key, required this.actual});

  final int actual;

  static const _nombres = ['Elegí cancha', 'Confirmás', '¡Listo!'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Paso ${actual + 1} de ${_nombres.length}: ${_nombres[actual]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _nombres.length; i++) ...[
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
                    _nombres[i],
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
