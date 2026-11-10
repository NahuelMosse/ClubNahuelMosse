import 'package:flutter/material.dart';

import '../../../common/booking_card.dart';
import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_card.dart';

/// What is below the card: the countdown, the space, the date and the time, with the
/// reason if the booking was cancelled or voided.
class BookingDetail extends StatelessWidget {
  const BookingDetail({
    super.key,
    required this.booking,
    required this.account,
    required this.reason,
  });

  final Booking booking;
  final String? account;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = booking;
    final account = this.account;
    final reason = this.reason;
    final voided = r.status == BookingStatus.voided;
    return Padding(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (account != null) ...[
            Text(
              account,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 11 * 0.08,
                color: p.accentInk,
              ),
            ),
            const SizedBox(height: Spacing.s4),
          ],
          Text(r.space, style: Texts.mono.copyWith(color: p.textMuted)),
          const SizedBox(height: Spacing.s8),
          BookingDateAndTime(date: longDate(r.startsAt), time: scheduleOf(r)),
          if (reason != null) ...[
            const SizedBox(height: Spacing.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: voided ? p.stateDangerInk : p.textSecondary,
                ),
                const SizedBox(width: Spacing.s8),
                Expanded(
                  child: Text(
                    reason,
                    style: Texts.caption.copyWith(
                      color: voided ? p.stateDangerInk : p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
