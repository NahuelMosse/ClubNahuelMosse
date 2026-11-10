import 'package:flutter/material.dart';
import '../../../common/selectable_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// `Segmented-Tab`: Próximas o Historial.
class BookingsTabBar extends StatelessWidget {
  const BookingsTabBar({
    super.key,
    required this.history,
    required this.onSelect,
  });

  final bool history;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    Widget tab(String text, {required bool isHistory}) {
      final chosen = history == isHistory;
      return Expanded(
        child: SelectableChip(
          text: text,
          selected: chosen,
          onTap: () => onSelect(isHistory),
          minHeight: Spacing.s48,
          padding: EdgeInsets.zero,
          unselectedBackground: Colors.transparent,
          unselectedInk: p.textSecondary,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Spacing.radiusPill),
      ),
      child: Row(
        children: [
          tab(l.bookingTabUpcoming, isHistory: false),
          const SizedBox(width: Spacing.s4),
          tab(l.bookingTabHistory, isHistory: true),
        ],
      ),
    );
  }
}
