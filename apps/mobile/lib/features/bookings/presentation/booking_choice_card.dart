// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../venues/presentation/photos.dart';
import '../domain/booking_choice.dart';
import 'total_row.dart';

/// La tarjeta de la elección: la foto con el tipo y la sede, las [filas] y el total.
class BookingChoiceCard extends StatelessWidget {
  const BookingChoiceCard({
    super.key,
    required this.eleccion,
    required this.filas,
  });

  final BookingChoice eleccion;
  final List<Widget> filas;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final e = eleccion;
    return CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: PhotoWithScrim(
              image: sportPhoto(e.space.sport),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      e.kind,
                      style: Texts.overline.copyWith(color: p.accentOnMedia),
                    ),
                    Text(
                      e.venue.name.toUpperCase(),
                      style: Texts.h2.copyWith(color: p.textOnMedia),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...filas,
                Divider(height: 1, color: p.borderDefault),
                const SizedBox(height: Spacing.s16),
                TotalRow(total: e.total),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
