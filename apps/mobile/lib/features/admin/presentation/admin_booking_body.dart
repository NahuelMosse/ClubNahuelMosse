import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking_history_entry.dart';
import 'booking_detail.dart';
import 'booking_header.dart';

/// What a booking tells in the admin list: sport, price and status, venue, user, space,
/// date and schedule, and the notice of the space's deactivation.
class AdminBookingBody extends StatelessWidget {
  const AdminBookingBody({
    super.key,
    required this.booking,
    required this.sportName,
    required this.schedule,
  });

  final BookingHistoryEntry booking;
  final String sportName;
  final String schedule;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final b = booking;
    return Padding(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookingHeader(
            booking: b,
            sportName: sportName,
            priceStatusGap: Spacing.s4,
            gapBeforePrice: Spacing.s8,
            stackOnLargeText: true,
          ),
          BookingDetail(
            booking: b,
            schedule: schedule,
            gapBeforeVenue: Spacing.s4,
            dateTimeGap: Spacing.s4,
          ),
          if (b.spaceDeactivated) ...[
            const SizedBox(height: Spacing.s8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: p.textMuted),
                const SizedBox(width: Spacing.s4),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context).adminSpaceDeactivated,
                    style: Texts.caption.copyWith(color: p.textMuted),
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
