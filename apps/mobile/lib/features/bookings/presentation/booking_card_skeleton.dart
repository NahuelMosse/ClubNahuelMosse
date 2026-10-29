import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

const _cardHeight = 260.0;
const _cards = 2;

/// The booking cards while the list loads, under one zone.
class BookingCardSkeletons extends StatelessWidget {
  const BookingCardSkeletons({super.key});

  @override
  Widget build(BuildContext context) => SkeletonZone(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _cards; i++) ...[
          if (i > 0) const SizedBox(height: Spacing.s12),
          const BookingCardSkeleton(),
        ],
      ],
    ),
  );
}

/// One booking card: same box as the real one.
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const Skeleton(height: _cardHeight, radius: Spacing.radiusLg);
}
