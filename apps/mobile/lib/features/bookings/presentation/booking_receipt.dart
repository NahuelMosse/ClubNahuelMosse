import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../common/die_cut.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/booking.dart';
import 'detail_row.dart';
import 'total_row.dart';

/// El aviso de la hora y el troquel con espacio, fecha, horario y total de la reserva.
class BookingReceipt extends StatelessWidget {
  const BookingReceipt({super.key, required this.reserva});

  final Booking reserva;

  String _horario(AppLocalizations l) {
    final r = reserva;
    final hours = r.endsAt.difference(r.startsAt).inHours;
    return '${timeRange(r.startsAt, r.endsAt)} · ${l.bookingDuration(hours)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final r = reserva;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.bookingReceiptNote,
            textAlign: TextAlign.center,
            style: Texts.body.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Spacing.s24),
          CardFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Spacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DetailRow(
                        dato: l.bookingRowSpace,
                        valor: r.space,
                        codigo: true,
                      ),
                      DetailRow(
                        dato: l.bookingRowDate,
                        valor: longDate(r.startsAt),
                      ),
                      DetailRow(dato: l.bookingRowTime, valor: _horario(l)),
                    ],
                  ),
                ),
                DieCut(background: p.bgBase),
                Padding(
                  padding: const EdgeInsets.all(Spacing.s16),
                  child: TotalRow(total: r.total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
