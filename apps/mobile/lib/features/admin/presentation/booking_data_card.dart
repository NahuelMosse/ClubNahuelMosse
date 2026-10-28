import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../common/price_format.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_history_entry.dart';
import 'booking_detail.dart';
import 'booking_header.dart';

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
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$sportName, sede ${b.venue}, ${b.address}, ${formatPesos(b.total)}, '
          '${b.status.apiValue}, usuario ${b.user}, ${b.space}, '
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
