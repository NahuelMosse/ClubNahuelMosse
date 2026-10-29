// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/motion.dart';
import '../../../common/sport_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../venues/presentation/photos.dart';
import '../domain/tile_animation.dart';
import 'home_title.dart';

/// Los deportes del club. Cada uno abre «Buscar cancha» con ese deporte elegido.
class HomeSports extends StatelessWidget {
  const HomeSports({super.key, required this.catalogo, required this.yaEntro});

  final Catalog catalogo;
  final bool yaEntro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
            child: HomeTitle(AppLocalizations.of(context).homeSports),
          ),
          const SizedBox(height: Spacing.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
            child: Row(
              children: [
                for (final (i, d) in catalogo.sports.indexed) ...[
                  if (i > 0) const SizedBox(width: Spacing.s12),
                  FadeIn(
                    delay: tileEntrance + tileStep * i,
                    duration: const Duration(milliseconds: 550),
                    fromX: 120,
                    fromY: 0,
                    turn: -8 / 360,
                    curve: AppMotion.bounce,
                    alreadyEntered: yaEntro,
                    child: SportTile(
                      image: sportPhoto(d.key),
                      emoji: emojiDeDeporte(d.key),
                      name: d.name,
                      onTap: () => context.go(
                        Uri(
                          path: '/inicio/buscar',
                          queryParameters: {'deporte': d.key},
                        ).toString(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El emoji de un deporte del catálogo; uno que la app no conoce lleva 🏅.
String emojiDeDeporte(String clave) => switch (clave) {
  'Futbol' => '⚽',
  'Tenis' => '🎾',
  'Padel' => '🏓',
  'Voley' => '🏐',
  'Hockey' => '🏑',
  'Basquet' => '🏀',
  'Golf' => '⛳',
  _ => '🏅',
};
