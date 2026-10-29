// kit-boundary: the loading pieces live with skeleton.dart, skeleton_list.dart and skeleton_zone.dart in common/.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The frame of a card while it loads: same box as the real one, with its lines inside.
class SkeletonCardFrame extends StatelessWidget {
  const SkeletonCardFrame({
    super.key,
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.all(Spacing.s16),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.borderDefault),
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
    ),
    child: child,
  );
}
