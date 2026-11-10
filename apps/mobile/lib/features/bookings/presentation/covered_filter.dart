import 'package:flutter/material.dart';

import '../../../common/selectable_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// Los chips Todas / Al aire libre / Techada con cuántas canchas trae cada uno.
class CoveredFilter extends StatelessWidget {
  const CoveredFilter({
    super.key,
    required this.total,
    required this.outdoor,
    required this.chosen,
    required this.onSelect,
  });

  final int total;
  final int outdoor;

  /// `null` es «Todas».
  final bool? chosen;
  final ValueChanged<bool?> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (value, count) in [
            (null, total),
            (false, outdoor),
            (true, total - outdoor),
          ]) ...[
            SelectableChip(
              text:
                  '${switch (value) {
                    null => l.spaceSearchAll,
                    false => l.spaceOpenAir,
                    true => l.spaceCovered,
                  }} ($count)',
              selected: chosen == value,
              onTap: count == 0 ? null : () => onSelect(value),
              minHeight: Spacing.s48,
              bordered: true,
              disabledInk: p.textMuted,
            ),
            const SizedBox(width: Spacing.s8),
          ],
        ],
      ),
    );
  }
}
