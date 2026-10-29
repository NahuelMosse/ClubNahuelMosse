import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_history_entry.dart';
import 'booking_detail.dart';
import 'booking_header.dart';
import 'booking_status_text.dart';

class BookingDataCard extends StatelessWidget {
  const BookingDataCard({
    super.key,
    required this.booking,
    required this.schedule,
    required this.sportName,
  });

  final BookingHistoryEntry booking;
  final String schedule;
  final String sportName;

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$sportName, ${l10n.adminVenueWord} ${b.venue}, ${b.address}, ${formatPesos(b.total)}, '
          '${statusChipText(l10n, b.status).toLowerCase()}, ${l10n.adminUserWord} ${b.user}, ${b.space}, '
          '${longDate(b.startsAt)}, $schedule',
      child: CardFrame(
        clip: Clip.none,
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingHeader(
              booking: b,
              sportName: sportName,
              priceStatusGap: Spacing.s8,
            ),
            BookingDetail(
              booking: b,
              schedule: schedule,
              gapBeforeVenue: Spacing.s8,
            ),
          ],
        ),
      ),
    );
  }
}
