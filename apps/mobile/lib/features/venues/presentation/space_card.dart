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

/// `Card-Cancha`: the photo of its sport with the type and the name, its data, the price
/// and «VER HORARIOS / RESERVAR».
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
            // Without this, the screen reader hears the same button on every court.
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
