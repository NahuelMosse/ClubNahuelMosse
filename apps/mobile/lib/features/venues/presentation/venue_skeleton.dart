// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../common/skeleton_cover.dart';
import '../../../l10n/app_localizations.dart';
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
  Widget build(BuildContext context) => SkeletonCover(
    coverBelowTop: _coverBelowTop,
    bodyPadding: const EdgeInsets.fromLTRB(
      Spacing.s24,
      Spacing.s24,
      Spacing.s24,
      Spacing.s40,
    ),
    body: const _Body(),
    backLabel: AppLocalizations.of(context).venueBack,
    onBack: onBack,
  );
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
