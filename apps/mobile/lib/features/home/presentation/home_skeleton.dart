// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';
import 'home_title.dart';

/// El Home mientras llega: la tarjeta de la próxima reserva, los deportes y los accesos,
/// con las mismas medidas que tendrán cuando lleguen.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  static const _bookingHeight = 280.0;
  static const _tileWidth = 124.0;
  static const _tileHeight = 148.0;
  static const _tileRadius = 20.0;
  static const _shortcutHeight = 134.0;
  static const _tileCount = 3;

  @override
  Widget build(BuildContext context) {
    return SkeletonZone(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Booking(),
          const Padding(
            padding: EdgeInsets.only(top: Spacing.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Spacing.s24),
                  child: HomeTitle('DEPORTES'),
                ),
                SizedBox(height: Spacing.s12),
                _Tiles(),
              ],
            ),
          ),
          const _Shortcuts(),
        ],
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(
      Spacing.s24,
      Spacing.s32,
      Spacing.s24,
      Spacing.s40,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeTitle('ACCESOS RÁPIDOS'),
        SizedBox(height: Spacing.s12),
        Row(
          children: [
            Expanded(
              child: Skeleton(
                key: ValueKey('skeleton-shortcut'),
                height: HomeSkeleton._shortcutHeight,
                radius: Spacing.radiusLg,
              ),
            ),
            SizedBox(width: Spacing.s12),
            Expanded(
              child: Skeleton(
                key: ValueKey('skeleton-shortcut'),
                height: HomeSkeleton._shortcutHeight,
                radius: Spacing.radiusLg,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Booking extends StatelessWidget {
  const _Booking();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s24,
        Spacing.s24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HomeTitle('TU PRÓXIMA RESERVA'),
          const SizedBox(height: Spacing.s12),
          Container(
            key: const ValueKey('skeleton-card'),
            height: HomeSkeleton._bookingHeight,
            padding: const EdgeInsets.all(Spacing.s16),
            decoration: BoxDecoration(
              border: Border.all(color: p.borderDefault),
              borderRadius: BorderRadius.circular(Spacing.radiusLg),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 120, height: 14),
                SizedBox(height: Spacing.s12),
                Skeleton(width: 200, height: 20),
                SizedBox(height: Spacing.s8),
                Skeleton(width: 160, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
    child: Row(
      children: [
        for (var i = 0; i < HomeSkeleton._tileCount; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.s12),
          const _Tile(),
        ],
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile();

  @override
  Widget build(BuildContext context) => const Skeleton(
    key: ValueKey('skeleton-tile'),
    width: HomeSkeleton._tileWidth,
    height: HomeSkeleton._tileHeight,
    radius: HomeSkeleton._tileRadius,
  );
}
