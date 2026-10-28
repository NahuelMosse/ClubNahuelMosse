import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/card_frame.dart';
import '../../../common/price_format.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import 'labels_and_price.dart';
import 'space_photo.dart';

/// `Card-Cancha`: la foto de su deporte con el tipo y el nombre, sus datos, el precio y
/// «VER HORARIOS / RESERVAR».
class SpaceCard extends StatelessWidget {
  const SpaceCard({
    super.key,
    required this.space,
    required this.catalog,
    required this.onBook,
  });

  final Space space;
  final Catalog catalog;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final kind = catalog.shortKind(space.sport, space.kind);
    final price = formatPesos(space.pricePerHour);
    return CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label:
                '$kind, ${space.name}, ${space.condition}, '
                '${space.lighting}, '
                '${price.replaceFirst('\$ ', '')} pesos por hora',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SpacePhoto(space: space, kind: kind),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.s16,
                    Spacing.s16,
                    Spacing.s16,
                    0,
                  ),
                  child: LabelsAndPrice(space: space, price: price),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.s16,
                    Spacing.s12,
                    Spacing.s16,
                    0,
                  ),
                  child: Text(
                    '${catalog.readableKind(space.sport, space.kind)} · '
                    '${space.condition} · '
                    '${space.lit ? 'con iluminación' : 'sin iluminación'}',
                    style: Texts.caption.copyWith(color: p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Spacing.s16),
            // Sin esto, el lector de pantalla oye el mismo botón en cada cancha.
            child: Semantics(
              label: '$kind, cancha ${space.number}',
              child: PrimaryButton(
                label: 'VER HORARIOS / RESERVAR',
                icon: Icons.bolt_rounded,
                onTap: onBook,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
