// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/button.dart';
import '../../../common/card_frame.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/space_texts.dart';
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
    final l = AppLocalizations.of(context);
    final kind = catalog.shortKind(space.sport, space.kind);
    final price = formatPesos(space.pricePerHour);
    return CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            excludeSemantics: true,
            label: l.spaceSpoken(
              conditionText(l, space),
              kind,
              lightingText(l, space),
              space.name,
              price.replaceFirst(RegExp(r'^\$\s'), ''),
            ),
            //                '${price.replaceFirst('\$ ', '')} pesos por hora',
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
                    '${conditionText(l, space)} · '
                    '${space.lit ? l.spaceWithLighting : l.spaceWithoutLighting}',
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
              label: l.spaceBookLabel(kind, space.number),
              child: PrimaryButton(
                label: l.spaceBook,
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
