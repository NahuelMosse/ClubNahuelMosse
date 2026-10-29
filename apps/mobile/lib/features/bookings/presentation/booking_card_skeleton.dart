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

/// One booking card: same box as the real one, with the places of its thumbnail, sport and
/// venue, price and status, space, date and buttons.
class BookingCardSkeleton extends StatelessWidget {
  const BookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    height: _cardHeight,
    padding: const EdgeInsets.all(Spacing.s16),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.borderDefault),
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Skeleton(width: 56, height: 56),
            SizedBox(width: Spacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 120, height: 18),
                  SizedBox(height: Spacing.s8),
                  Skeleton(width: 160, height: 14),
                ],
              ),
            ),
            SizedBox(width: Spacing.s12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Skeleton(width: 64, height: 18),
                SizedBox(height: Spacing.s8),
                Skeleton(width: 72, height: 20, radius: Spacing.radiusLg),
              ],
            ),
          ],
        ),
        SizedBox(height: Spacing.s16),
        Skeleton(height: 1),
        SizedBox(height: Spacing.s16),
        Skeleton(width: 140, height: 16),
        SizedBox(height: Spacing.s8),
        Skeleton(width: 190, height: 14),
        Spacer(),
        Row(
          children: [
            Expanded(child: Skeleton(height: Spacing.controlHeight)),
            SizedBox(width: Spacing.s12),
            Expanded(child: Skeleton(height: Spacing.controlHeight)),
          ],
        ),
      ],
    ),
  );
}
