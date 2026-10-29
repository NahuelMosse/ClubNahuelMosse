// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

/// What the cards of a listing show: a space has the sport block and two lines; a venue
/// has the same header and the schedule line below.
enum AdminCardShape { space, venue }

/// The cards of «Gestionar espacios» and «Gestionar sedes» while they load: the frame, the
/// details and the two buttons of the real card, in the place of each.
class AdminCardSkeletons extends StatelessWidget {
  const AdminCardSkeletons({super.key, required this.shape, this.count = 3});

  final AdminCardShape shape;
  final int count;

  @override
  Widget build(BuildContext context) => SkeletonZone(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 160, height: 14),
        ),
        const SizedBox(height: Spacing.s16),
        for (var i = 0; i < count; i++) ...[
          _Frame(shape: shape),
          if (i < count - 1) const SizedBox(height: Spacing.s12),
        ],
      ],
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame({required this.shape});

  final AdminCardShape shape;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('skeleton-card'),
    padding: const EdgeInsets.all(Spacing.s16),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.borderDefault),
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(shape: shape),
        if (shape == AdminCardShape.venue) ...[
          const SizedBox(height: Spacing.s12),
          const Skeleton(height: 16),
        ],
        const SizedBox(height: Spacing.s12),
        const Row(
          children: [
            Expanded(child: Skeleton(height: Spacing.controlHeight)),
            SizedBox(width: Spacing.s8),
            Expanded(child: Skeleton(height: Spacing.controlHeight)),
          ],
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.shape});

  final AdminCardShape shape;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Skeleton(width: Spacing.touchTarget, height: Spacing.touchTarget),
      const SizedBox(width: Spacing.s12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: 160, height: 18),
            const SizedBox(height: Spacing.s8),
            const Skeleton(width: 120, height: 14),
            // The description of a space wraps to a second line.
            if (shape == AdminCardShape.space) ...[
              const SizedBox(height: Spacing.s12),
              const Skeleton(width: 140, height: 14),
              const SizedBox(height: Spacing.s4),
              const Skeleton(width: 100, height: 14),
            ],
          ],
        ),
      ),
    ],
  );
}
