import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../common/price_format.dart';
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
    final b = booking;
    return Container(
      padding: const EdgeInsets.all(Spacing.s16),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Spacing.radiusMd),
      ),
      child: Column(
        children: [
          VoidDetail('Usuario', b.user),
          VoidDetail('Sede', b.venue),
          VoidDetail('Cancha', b.space, technical: true),
          VoidDetail('Cuándo', '${longDate(b.startsAt)}\n$schedule'),
          VoidDetail('Importe', formatPesos(b.total)),
        ],
      ),
    );
  }
}
