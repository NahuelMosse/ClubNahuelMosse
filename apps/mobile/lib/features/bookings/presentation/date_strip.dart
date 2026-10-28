import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/search_rules.dart';
import 'selectable_frame.dart';

/// Los próximos siete días desde hoy, en una fila que se desliza.
class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.hoy,
    required this.elegida,
    required this.alElegir,
  });

  final DateTime hoy;
  final DateTime? elegida;
  final ValueChanged<DateTime> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < daysInView; i++) ...[
            if (i > 0) const SizedBox(width: Spacing.s8),
            Builder(
              builder: (context) {
                final dia = DateTime.utc(hoy.year, hoy.month, hoy.day + i);
                final esta = dia == elegida;
                final tinta = esta ? p.accentOn : p.textPrimary;
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 64,
                  ),
                  child: SelectableFrame(
                    etiqueta: '${weekdayName(dia)} ${dia.day}',
                    elegido: esta,
                    alTocar: () => alElegir(dia),
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.s8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weekdayAbbreviation(dia),
                            style: Texts.overline.copyWith(
                              color: esta ? p.accentOn : p.textMuted,
                            ),
                          ),
                          Text(
                            '${dia.day}',
                            style: Texts.h2.copyWith(color: tinta),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
