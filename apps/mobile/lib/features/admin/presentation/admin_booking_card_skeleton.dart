// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

/// Height of a booking card of the admin history with its ANULAR RESERVA button.
const adminBookingCardHeight = 190.0;

/// A booking card of the history while it loads: the frame, the lines of the booking and
/// the place of its button.
class AdminBookingCardSkeleton extends StatelessWidget {
  const AdminBookingCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('skeleton-card'),
    height: adminBookingCardHeight,
    padding: const EdgeInsets.all(Spacing.s16),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.borderDefault),
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Skeleton(width: 120, height: 20),
            Skeleton(width: 72, height: 20),
          ],
        ),
        SizedBox(height: Spacing.s12),
        Skeleton(width: 180, height: 14),
        SizedBox(height: Spacing.s8),
        Skeleton(width: 140, height: 14),
        SizedBox(height: Spacing.s8),
        Skeleton(width: 200, height: 14),
        Spacer(),
        Skeleton(height: Spacing.controlHeight),
      ],
    ),
  );
}

/// The place of the next page of the history while it is requested: one block of the
/// height of a booking.
class NextPageSkeleton extends StatelessWidget {
  const NextPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SkeletonZone(
    child: Skeleton(height: adminBookingCardHeight, radius: Spacing.radiusLg),
  );
}
