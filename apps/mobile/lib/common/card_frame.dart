import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The frame of a card: raised surface, border and rounded corners.
class CardFrame extends StatelessWidget {
  const CardFrame({
    super.key,
    required this.child,
    this.padding,
    this.clip = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// How the content is clipped against the rounded corners.
  final Clip clip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      clipBehavior: clip,
      padding: padding,
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Spacing.radiusLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: child,
    );
  }
}
