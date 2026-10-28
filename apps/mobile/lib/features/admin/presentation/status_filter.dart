// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import 'admin_filter_chip.dart';

/// «Todas» and the booking statuses; [onSelect] receives the tapped one, or `null` for «Todas».
class StatusFilter extends StatelessWidget {
  const StatusFilter({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final BookingStatus? selected;
  final ValueChanged<BookingStatus?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.s8,
      runSpacing: Spacing.s8,
      children: [
        AdminFilterChip(
          text: 'Todas',
          onTap: () => onSelect(null),
          selected: selected == null,
        ),
        for (final e in const [
          BookingStatus.active,
          BookingStatus.completed,
          BookingStatus.voided,
        ])
          AdminFilterChip(
            text: switch (e) {
              BookingStatus.active => 'Activas',
              BookingStatus.completed => 'Completadas',
              _ => 'Anuladas',
            },
            onTap: () => onSelect(e),
            selected: selected == e,
          ),
      ],
    );
  }
}
