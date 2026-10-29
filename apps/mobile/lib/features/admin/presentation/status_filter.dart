// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import 'admin_filter_chip.dart';
import 'booking_status_text.dart';

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
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: Spacing.s8,
      runSpacing: Spacing.s8,
      children: [
        for (final status in const [
          null,
          BookingStatus.active,
          BookingStatus.completed,
          BookingStatus.voided,
        ])
          AdminFilterChip(
            text: statusFilterText(l10n, status),
            onTap: () => onSelect(status),
            selected: selected == status,
          ),
      ],
    );
  }
}
