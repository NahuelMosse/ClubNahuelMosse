import 'package:flutter/material.dart';

import '../../../common/card_frame.dart';
import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

/// How many court cards a loading list shows.
const _skeletonCards = 2;

/// The blocks of a court card, in the places of its photo, labels, price, details and button.
class SpaceCardSkeleton extends StatelessWidget {
  const SpaceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const CardFrame(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 180, radius: 0),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.s16,
            Spacing.s16,
            Spacing.s16,
            0,
          ),
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                Skeleton(width: 84, height: 24, radius: Spacing.radiusPill),
                SizedBox(width: Spacing.s4),
                Skeleton(width: 84, height: 24, radius: Spacing.radiusPill),
                Spacer(),
                Skeleton(width: 88, height: 42),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.s16,
            Spacing.s12,
            Spacing.s16,
            0,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 220, height: 18),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(Spacing.s16),
          child: Skeleton(height: Spacing.controlHeight),
        ),
      ],
    ),
  );
}

/// The court cards of a loading venue; the caller puts them under a `SkeletonZone`.
class SpaceCardSkeletons extends StatelessWidget {
  const SpaceCardSkeletons({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < _skeletonCards; i++) ...[
        if (i > 0) const SizedBox(height: Spacing.s16),
        const SpaceCardSkeleton(),
      ],
    ],
  );
}
