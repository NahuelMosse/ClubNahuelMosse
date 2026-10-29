// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/selectable_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../domain/counters.dart';
import 'booking_status_text.dart';

class AdminTabBar extends StatelessWidget {
  const AdminTabBar({
    super.key,
    required this.selected,
    required this.counters,
    required this.onSelect,
  });

  final BookingStatus? selected;
  final Counters? counters;
  final ValueChanged<BookingStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = counters;
    final l10n = AppLocalizations.of(context);
    Widget tab(BookingStatus? value, int? count) {
      final active = selected == value;
      final text = statusFilterText(l10n, value);
      final label = count == null ? text : '$text ($count)';
      final p = context.palette;
      return Padding(
        padding: const EdgeInsets.only(right: Spacing.s8),
        child: SelectableChip(
          text: label,
          selected: active,
          onTap: () => onSelect(value),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.s16,
            vertical: Spacing.s12,
          ),
          unselectedInk: p.textSecondary,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          tab(null, c?.all),
          tab(BookingStatus.active, c?.active),
          tab(BookingStatus.completed, c?.completed),
          tab(BookingStatus.voided, c?.voided),
        ],
      ),
    );
  }
}
