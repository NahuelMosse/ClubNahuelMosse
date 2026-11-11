// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/sport_icons.dart';
import '../../venues/presentation/photos.dart';
import '../domain/booking.dart';
import 'booking_price_and_status.dart';

/// The photo of the sport, the court type with the venue and, if the font is not large,
/// the price and the status on the right.
class BookingHeader extends StatelessWidget {
  const BookingHeader({
    super.key,
    required this.booking,
    required this.catalog,
    required this.large,
  });

  final Booking booking;
  final Catalog catalog;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = booking;
    return Padding(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Spacing.radiusMd),
            child: Image(
              image: sportPhoto(r.sport),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: Spacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(sportIcon(r.sport), size: 16, color: p.textSecondary),
                    const SizedBox(width: Spacing.s4),
                    Flexible(
                      child: Text(
                        catalog.shortKind(r.sport, r.kind),
                        style: Texts.title.copyWith(color: p.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s4),
                Text(
                  '${r.venue} · ${r.address}',
                  style: Texts.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          if (!large) ...[
            const SizedBox(width: Spacing.s8),
            BookingPriceAndStatus(booking: r, large: large),
          ],
        ],
      ),
    );
  }
}
