import 'package:flutter/material.dart';

import '../../../common/booking_card.dart';
import '../../../common/dates.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking.dart';
import '../domain/booking_status.dart';
import 'booking_card.dart';

/// Lo de abajo de la tarjeta: la cuenta regresiva, el espacio, la fecha y el horario, con
/// el porqué si la reserva se canceló o se anuló.
class BookingDetail extends StatelessWidget {
  const BookingDetail({
    super.key,
    required this.reserva,
    required this.cuenta,
    required this.porque,
  });

  final Booking reserva;
  final String? cuenta;
  final String? porque;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = reserva;
    final cuenta = this.cuenta;
    final porque = this.porque;
    final anulada = r.status == BookingStatus.voided;
    return Padding(
      padding: const EdgeInsets.all(Spacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cuenta != null) ...[
            Text(
              cuenta,
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
          BookingDateAndTime(date: longDate(r.startsAt), time: horarioDe(r)),
          if (porque != null) ...[
            const SizedBox(height: Spacing.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: anulada ? p.stateDangerInk : p.textSecondary,
                ),
                const SizedBox(width: Spacing.s8),
                Expanded(
                  child: Text(
                    porque,
                    style: Texts.caption.copyWith(
                      color: anulada ? p.stateDangerInk : p.textSecondary,
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
