import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import 'space_card_skeleton.dart';

/// Height of the cover under the status bar, up to where the filters begin.
const _coverBelowTop = 202.0;
const _sportChips = 3;

/// A venue while it loads: the cover, the filters and the court cards where they will be.
/// The way back is real, so the person can leave while it loads.
class VenueSkeleton extends StatelessWidget {
  const VenueSkeleton({super.key, required this.onBack});

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
                Skeleton(height: top + _coverBelowTop, radius: 0),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    Spacing.s24,
                    Spacing.s24,
                    Spacing.s24,
                    Spacing.s40,
                  ),
                  child: _Body(),
                ),
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
              label: const Text('Todas las sedes'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(
        height: 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Skeleton(width: 64, height: 14),
        ),
      ),
      const SizedBox(height: Spacing.s8),
      Wrap(
        spacing: Spacing.s8,
        runSpacing: Spacing.s8,
        children: [
          for (var i = 0; i < _sportChips; i++)
            const Skeleton(width: 105, height: 48, radius: Spacing.radiusPill),
        ],
      ),
      const SizedBox(height: Spacing.s24),
      const Align(
        alignment: Alignment.centerLeft,
        child: Skeleton(width: 180, height: 14),
      ),
      const SizedBox(height: Spacing.s12),
      const SpaceCardSkeletons(),
    ],
  );
}
