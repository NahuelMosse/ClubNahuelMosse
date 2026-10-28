import 'package:flutter/material.dart';

import '../../../common/booking_card.dart';
import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_history_entry.dart';

/// Venue, user, space, date and schedule of an admin booking.
class BookingDetail extends StatelessWidget {
  const BookingDetail({
    super.key,
    required this.booking,
    required this.schedule,
    required this.gapBeforeVenue,
    this.dateTimeGap = Spacing.s8,
  });

  final BookingHistoryEntry booking;
  final String schedule;
  final double gapBeforeVenue;
  final double dateTimeGap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final b = booking;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: gapBeforeVenue),
        Text(
          '${b.venue} · ${b.address}',
          style: Texts.caption.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Spacing.s12),
        BookingUser(user: b.user),
        const SizedBox(height: Spacing.s8),
        Text(b.space, style: Texts.mono.copyWith(color: p.textMuted)),
        const SizedBox(height: Spacing.s8),
        BookingDateAndTime(
          date: longDate(b.startsAt),
          time: schedule,
          verticalGap: dateTimeGap,
          alignment: WrapCrossAlignment.start,
        ),
      ],
    );
  }
}
