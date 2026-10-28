// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

export 'skeleton_list.dart';
export 'skeleton_zone.dart';

/// A rounded grey block: the place of something that has not arrived yet.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = Spacing.radiusMd,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: dark ? p.bgSurfaceRaised : p.bgSurface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
