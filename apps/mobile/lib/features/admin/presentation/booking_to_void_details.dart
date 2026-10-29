import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_history_entry.dart';
import 'void_detail.dart';

/// The table with the data of the booking about to be voided.
class BookingToVoidDetails extends StatelessWidget {
  const BookingToVoidDetails({
    super.key,
    required this.booking,
    required this.schedule,
  });

  final BookingHistoryEntry booking;
  final String schedule;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final b = booking;
    return Container(
      padding: const EdgeInsets.all(Spacing.s16),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
      ),
      child: Column(
        children: [
          VoidDetail(l10n.adminUser, b.user),
          VoidDetail(l10n.adminVenue, b.venue),
          VoidDetail(l10n.adminCourt, b.space, technical: true),
          VoidDetail(l10n.adminWhen, '${longDate(b.startsAt)}\n$schedule'),
          VoidDetail(l10n.adminAmount, formatPesos(b.total)),
        ],
      ),
    );
  }
}
