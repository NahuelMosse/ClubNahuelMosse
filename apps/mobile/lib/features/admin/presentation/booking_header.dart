// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/presentation/sport_icons.dart';
import '../domain/booking_history_entry.dart';
import 'booking_status_chip.dart';

/// Sport, price and status of a booking. With `stackOnLargeText`, and very enlarged text,
/// price and status drop below the name instead of competing with it for width.
class BookingHeader extends StatelessWidget {
  const BookingHeader({
    super.key,
    required this.booking,
    required this.sportName,
    required this.priceStatusGap,
    this.gapBeforePrice = 0,
    this.stackOnLargeText = false,
  });

  final BookingHistoryEntry booking;
  final String sportName;
  final double priceStatusGap;
  final double gapBeforePrice;
  final bool stackOnLargeText;

  Widget _priceAndStatus(Palette p) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        formatPesos(booking.total),
        style: Texts.bodyStrong.copyWith(color: p.accentInk),
      ),
      SizedBox(height: priceStatusGap),
      BookingStatusChip(status: booking.status),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // With any text enlargement, price and status no longer fit next to the name at 360.
    final stack =
        stackOnLargeText && MediaQuery.textScalerOf(context).scale(10) > 13;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(sportIcon(booking.sport), size: 20, color: p.textSecondary),
            const SizedBox(width: Spacing.s8),
            Expanded(
              child: Text(
                sportName,
                style: Texts.title.copyWith(color: p.textPrimary),
              ),
            ),
            if (!stack) ...[
              SizedBox(width: gapBeforePrice),
              _priceAndStatus(p),
            ],
          ],
        ),
        if (stack) ...[const SizedBox(height: Spacing.s8), _priceAndStatus(p)],
      ],
    );
  }
}
