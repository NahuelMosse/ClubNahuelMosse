import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../domain/booking_history_entry.dart';
import 'admin_booking_card.dart';

/// The sliver with the cards of the loaded bookings. A `null` [onVoid] disables
/// ANULAR RESERVA on all of them.
class AdminBookingsList extends StatelessWidget {
  const AdminBookingsList({
    super.key,
    required this.bookings,
    required this.catalog,
    required this.onTap,
    required this.onVoid,
  });

  final List<BookingHistoryEntry> bookings;
  final Catalog? catalog;
  final ValueChanged<BookingHistoryEntry> onTap;
  final ValueChanged<BookingHistoryEntry>? onVoid;

  @override
  Widget build(BuildContext context) {
    final voidBooking = onVoid;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        0,
        Spacing.s24,
        Spacing.s40,
      ),
      sliver: SliverList.builder(
        itemCount: bookings.length,
        itemBuilder: (context, i) {
          final b = bookings[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: Spacing.s12),
            child: AdminBookingCard(
              booking: b,
              catalog: catalog,
              onTap: () => onTap(b),
              onVoid: voidBooking == null ? null : () => voidBooking(b),
            ),
          );
        },
      ),
    );
  }
}
