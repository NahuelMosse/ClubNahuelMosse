import 'package:flutter/material.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'skeleton.dart';

/// A page that loads under a cover: the cover block under the status bar, the body where it will
/// be and a real way back, so the person can leave while it loads.
class SkeletonCover extends StatelessWidget {
  const SkeletonCover({
    super.key,
    required this.coverBelowTop,
    required this.bodyPadding,
    required this.body,
    required this.backLabel,
    required this.onBack,
  });

  /// Height of the cover under the status bar.
  final double coverBelowTop;
  final EdgeInsets bodyPadding;
  final Widget body;
  final String backLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      children: [
        SkeletonZone(
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Skeleton(height: top + coverBelowTop, radius: 0),
                Padding(padding: bodyPadding, child: body),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.only(left: Spacing.s12, top: Spacing.s8),
            child: TextButton.icon(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: p.textPrimary,
                minimumSize: const Size(0, Spacing.touchTarget),
                textStyle: Texts.caption,
              ),
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: Text(backLabel),
            ),
          ),
        ),
      ],
    );
  }
}
