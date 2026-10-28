// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The bar fixed at the bottom of a screen: [color] background, top border and the safe area.
class FixedBar extends StatelessWidget {
  const FixedBar({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Spacing.s24,
      vertical: Spacing.s16,
    ),
  });

  final Color color;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
