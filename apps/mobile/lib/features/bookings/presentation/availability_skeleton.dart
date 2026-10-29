// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../common/skeleton_cover.dart';
import '../../../theme/tokens.dart';
import 'paired_grid.dart';

/// Height of the cover under the status bar: back button, title and padding.
const _coverBelowTop = 164.0;
const _spaceCardHeight = 72.0;
const _dayWidth = 56.0;
const _dayHeight = 64.0;
const _daysInRow = 7;
const _durationHeight = 56.0;
const _captionHeight = 28.0;
const _titleHeight = 14.0;
const _titleRowHeight = 16.0;
const _dayLineHeight = 111.2;
const _slotBlocks = 12;

/// The schedules of a court while they load: the cover, the court cards, the days, the duration
/// and the slot grid where they will be. The way back is real, so the person can leave.
class AvailabilitySkeleton extends StatelessWidget {
  const AvailabilitySkeleton({
    super.key,
    required this.volverA,
    required this.alVolver,
  });

  final String volverA;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) => SkeletonCover(
    coverBelowTop: _coverBelowTop,
    bodyPadding: const EdgeInsets.fromLTRB(
      Spacing.s24,
      Spacing.s20,
      Spacing.s24,
      Spacing.s32,
    ),
    body: const _Body(),
    backLabel: volverA,
    onBack: alVolver,
  );
}

/// The slot grid of a court while it loads, in its own zone: the day line and twelve slots.
class AvailabilityGridSkeleton extends StatelessWidget {
  const AvailabilityGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const SkeletonZone(child: _GridBlocks());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Section(
        titleWidth: 140,
        child: PairedGrid(
          hijos: [
            Skeleton(height: _spaceCardHeight),
            Skeleton(height: _spaceCardHeight),
          ],
        ),
      ),
      _Section(titleWidth: 48, child: _Days()),
      _Section(
        titleWidth: 72,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton(height: _durationHeight),
            SizedBox(height: Spacing.s8),
            Align(
              alignment: Alignment.centerLeft,
              child: Skeleton(width: 240, height: _captionHeight),
            ),
          ],
        ),
      ),
      _Section(
        titleWidth: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 2),
            SizedBox(height: Spacing.s8),
            _GridBlocks(),
          ],
        ),
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.titleWidth, required this.child});

  final double titleWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Spacing.s24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _titleRowHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: titleWidth, height: _titleHeight),
          ),
        ),
        const SizedBox(height: Spacing.s8),
        child,
      ],
    ),
  );
}

class _Days extends StatelessWidget {
  const _Days();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    clipBehavior: Clip.none,
    child: Row(
      children: [
        for (var i = 0; i < _daysInRow; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.s8),
          const Skeleton(
            width: _dayWidth,
            height: _dayHeight,
            radius: Spacing.radiusLg,
          ),
        ],
      ],
    ),
  );
}

class _GridBlocks extends StatelessWidget {
  const _GridBlocks();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Skeleton(height: _dayLineHeight),
      const SizedBox(height: Spacing.s12),
      PairedGrid(
        alto: Spacing.controlHeight,
        hijos: [
          for (var i = 0; i < _slotBlocks; i++)
            const Skeleton(height: Spacing.controlHeight),
        ],
      ),
    ],
  );
}
