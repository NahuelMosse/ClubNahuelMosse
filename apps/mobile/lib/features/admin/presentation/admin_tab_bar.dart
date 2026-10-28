// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/selectable_chip.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../domain/counters.dart';

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
    Widget tab(String text, BookingStatus? value, int? count) {
      final active = selected == value;
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
          tab('Todas', null, c?.all),
          tab('Activas', BookingStatus.active, c?.active),
          tab('Completadas', BookingStatus.completed, c?.completed),
          tab('Anuladas', BookingStatus.voided, c?.voided),
        ],
      ),
    );
  }
}
