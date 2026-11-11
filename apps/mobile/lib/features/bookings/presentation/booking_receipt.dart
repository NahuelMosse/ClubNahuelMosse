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

/// The notice of the time and the die-cut with space, date, time and total of the
/// booking.
class BookingReceipt extends StatelessWidget {
  const BookingReceipt({super.key, required this.booking});

  final Booking booking;

  String _schedule(AppLocalizations l) {
    final r = booking;
    final hours = r.endsAt.difference(r.startsAt).inHours;
    return '${timeRange(r.startsAt, r.endsAt)} · ${l.bookingDuration(hours)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final r = booking;
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
                        label: l.bookingRowSpace,
                        value: r.space,
                        code: true,
                      ),
                      DetailRow(
                        label: l.bookingRowDate,
                        value: longDate(r.startsAt),
                      ),
                      DetailRow(label: l.bookingRowTime, value: _schedule(l)),
                    ],
                  ),
                ),
                const DieCut(),
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
