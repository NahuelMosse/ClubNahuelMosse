// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'skeleton.dart';

// kit-shape: _Notice is a private detail of the `notice` shape, it has no other use.
/// The shape of what is going to appear in a list.
enum SkeletonShape { venue, space, booking, notice, grid }

/// The blocks of a loading list, shaped like the real card.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, required this.shape, this.count = 3});

  final SkeletonShape shape;
  final int count;

  @override
  Widget build(BuildContext context) => SkeletonZone(
    child: SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: _gap),
            _row(),
          ],
        ],
      ),
    ),
  );

  double get _gap => shape == SkeletonShape.grid ? Spacing.s8 : Spacing.s12;

  Widget _row() => switch (shape) {
    SkeletonShape.venue => const Skeleton(
      height: 220,
      radius: Spacing.radiusLg,
    ),
    SkeletonShape.space => const Skeleton(height: 96),
    SkeletonShape.booking => const Skeleton(height: 112),
    SkeletonShape.notice => const _Notice(),
    SkeletonShape.grid => const Row(
      children: [
        Expanded(child: Skeleton(height: Spacing.controlHeight)),
        SizedBox(width: Spacing.s8),
        Expanded(child: Skeleton(height: Spacing.controlHeight)),
      ],
    ),
  };
}

class _Notice extends StatelessWidget {
  const _Notice();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 76,
    child: Row(
      children: [
        Skeleton(width: 40, height: 40),
        SizedBox(width: Spacing.s12),
        Expanded(child: Skeleton(height: 40)),
      ],
    ),
  );
}
