import 'package:flutter/material.dart';
import '../../../common/selectable_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';

/// `Segmented-Tab`: Próximas o Historial.
class BookingsTabBar extends StatelessWidget {
  const BookingsTabBar({
    super.key,
    required this.historial,
    required this.alElegir,
  });

  final bool historial;
  final ValueChanged<bool> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    Widget pestana(String texto, {required bool esHistorial}) {
      final elegida = historial == esHistorial;
      return Expanded(
        child: SelectableChip(
          text: texto,
          selected: elegida,
          onTap: () => alElegir(esHistorial),
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
          pestana(l.bookingTabUpcoming, esHistorial: false),
          const SizedBox(width: Spacing.s4),
          pestana(l.bookingTabHistory, esHistorial: true),
        ],
      ),
    );
  }
}
