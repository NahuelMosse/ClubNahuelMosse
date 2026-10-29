import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/dates.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../domain/slot.dart';

/// La tarjeta de resumen: el precio, y el total con el horario y la fecha elegidos.
class BookingSummary extends StatelessWidget {
  const BookingSummary({
    super.key,
    required this.tipo,
    required this.precio,
    required this.horas,
    required this.franja,
    required this.fecha,
  });

  final String tipo;
  final int precio;
  final int horas;
  final Slot? franja;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final elegida = franja;
    final dia = fecha;
    return Semantics(
      container: true,
      liveRegion: true,
      child: CardFrame(
        clip: Clip.none,
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Con el texto grande, cada dato baja a su propia línea en vez de cortarse.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Spacing.s8,
              runSpacing: Spacing.s4,
              children: [
                Text(tipo, style: Texts.body.copyWith(color: p.textSecondary)),
                Text(
                  elegida == null
                      ? l.bookingPerHour(formatPesos(precio))
                      : '${formatPesos(precio)} × $horas',
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
                      elegida == null ? '—' : formatPesos(precio * horas),
                      style: Texts.h1.copyWith(color: p.accentInk),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      elegida?.text ?? l.bookingNoTimeChosen,
                      style: Texts.bodyStrong.copyWith(
                        color: elegida == null
                            ? p.textSecondary
                            : p.textPrimary,
                      ),
                    ),
                    if (dia != null)
                      Text(
                        longDate(dia),
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
