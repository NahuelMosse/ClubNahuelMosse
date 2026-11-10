import 'package:flutter/material.dart';

import '../../../common/price_format.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking.dart';
import 'status_label.dart';

/// El total de la reserva y su estado, uno sobre el otro.
class BookingPriceAndStatus extends StatelessWidget {
  const BookingPriceAndStatus({
    super.key,
    required this.booking,
    required this.large,
  });

  final Booking booking;

  /// Con la letra grande se alinea a la izquierda en vez de a la derecha.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: large
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          formatPesos(booking.total),
          style: Texts.bodyStrong.copyWith(color: p.accentInk),
        ),
        const SizedBox(height: Spacing.s8),
        StatusLabel(status: booking.status),
      ],
    );
  }
}
