import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/slot.dart';

/// The summary card: the price, and the total with the chosen time and date.
class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
    required this.kind,
    required this.price,
    required this.hours,
    required this.slot,
    required this.date,
  });

  final String kind;
  final int price;
  final int hours;
  final Slot? slot;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final chosen = slot;
    final day = date;
    return Semantics(
      container: true,
      liveRegion: true,
      child: CardFrame(
        clip: Clip.none,
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // With large text, each datum drops to its own line instead of being cut off.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Spacing.s8,
              runSpacing: Spacing.s4,
              children: [
                Text(kind, style: Texts.body.copyWith(color: p.textSecondary)),
                Text(
                  chosen == null
                      ? l.bookingPerHour(formatPesos(price))
                      : '${formatPesos(price)} × $hours',
                  style: Texts.body.copyWith(color: p.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: Spacing.s12),
            Divider(height: 1, color: p.borderDefault),
            const SizedBox(height: Spacing.s12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Spacing.s8,
              runSpacing: Spacing.s8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.bookingTotal,
                      style: Texts.overline.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: Spacing.s4),
                    Text(
                      chosen == null ? '—' : formatPesos(price * hours),
                      style: Texts.h1.copyWith(color: p.accentInk),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chosen?.text ?? l.bookingNoTimeChosen,
                      style: Texts.bodyStrong.copyWith(
                        color: chosen == null ? p.textSecondary : p.textPrimary,
                      ),
                    ),
                    if (day != null)
                      Text(
                        longDate(day),
                        style: Texts.caption.copyWith(color: p.textMuted),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
