// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/motion.dart';
import '../../../common/sport_tile.dart';
import '../../../theme/tokens.dart';
import '../../spaces/domain/space.dart';
import '../../venues/presentation/photos.dart';
import '../domain/tile_animation.dart';
import 'home_sports_section.dart';

/// Los deportes del club. Cada uno abre «Buscar cancha» con ese deporte elegido.
class HomeSports extends StatelessWidget {
  const HomeSports({
    super.key,
    required this.catalog,
    required this.alreadyEntered,
  });

  final Catalog catalog;
  final bool alreadyEntered;

  @override
  Widget build(BuildContext context) {
    return HomeSportsSection(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
        child: Row(
          children: [
            for (final (i, d) in catalog.sports.indexed) ...[
              if (i > 0) const SizedBox(width: Spacing.s12),
              FadeIn(
                delay: tileEntrance + tileStep * i,
                duration: const Duration(milliseconds: 550),
                fromX: 120,
                fromY: 0,
                turn: -8 / 360,
                curve: AppMotion.bounce,
                alreadyEntered: alreadyEntered,
                child: SportTile(
                  image: sportPhoto(d.key),
                  emoji: sportEmoji(d.key),
                  name: d.name,
                  onTap: () => context.go(
                    Uri(
                      path: '/home/search',
                      queryParameters: {'sport': d.key},
                    ).toString(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// El emoji de un deporte del catálogo; uno que la app no conoce lleva 🏅.
String sportEmoji(String key) => switch (key) {
  'Futbol' => '⚽',
  'Tenis' => '🎾',
  'Padel' => '🏓',
  'Voley' => '🏐',
  'Hockey' => '🏑',
  'Basquet' => '🏀',
  'Golf' => '⛳',
  _ => '🏅',
};
