// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

/// The page under the title while the venues load: the subtitle line and three cards.
class VenueCardSkeletons extends StatelessWidget {
  const VenueCardSkeletons({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonZone(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: Spacing.s4),
        Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 220, height: 18),
        ),
        SizedBox(height: Spacing.s16),
        VenueCardSkeleton(),
        SizedBox(height: Spacing.s16),
        VenueCardSkeleton(),
        SizedBox(height: Spacing.s16),
        VenueCardSkeleton(),
      ],
    ),
  );
}

/// The blocks of a venue card: its cover, and below it the sports and the call to action.
class VenueCardSkeleton extends StatelessWidget {
  const VenueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: context.palette.bgSurface,
    borderRadius: BorderRadius.circular(Spacing.radiusLg),
    clipBehavior: Clip.antiAlias,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Skeleton(height: 158, radius: 0),
        Padding(
          padding: EdgeInsets.all(Spacing.s16),
          child: Row(
            children: [
              Skeleton(width: 72, height: 24, radius: Spacing.radiusPill),
              SizedBox(width: Spacing.s4),
              Skeleton(width: 72, height: 24, radius: Spacing.radiusPill),
              Spacer(),
              Skeleton(width: 96, height: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
