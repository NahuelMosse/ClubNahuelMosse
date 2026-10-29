import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';
import '../../venues/presentation/space_card_skeleton.dart';

const _labelHeight = 14.0;
const _boxHeight = 52.0;
const _filterFields = 4;
const _coveredFilterHeight = 48.0;
const _resultsTitleHeight = 14.0;

/// The search form while its options load: the real header and the fields where they will be.
class SpaceSearchSkeleton extends StatelessWidget {
  const SpaceSearchSkeleton({super.key, required this.header});

  /// The title and the intro line, which do not come from the server.
  final Widget header;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      Spacing.s24,
      Spacing.s8,
      Spacing.s24,
      Spacing.s40,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: Spacing.s16),
        const SkeletonZone(child: _Fields()),
      ],
    ),
  );
}

/// The court cards of a search while it runs, under the filters that stay.
class SpaceResultsSkeleton extends StatelessWidget {
  const SpaceResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: Spacing.s24),
    child: SkeletonZone(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Skeleton(height: _coveredFilterHeight),
          SizedBox(height: Spacing.s12),
          Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 220, height: _resultsTitleHeight),
          ),
          SizedBox(height: Spacing.s12),
          SpaceCardSkeletons(),
        ],
      ),
    ),
  );
}

class _Fields extends StatelessWidget {
  const _Fields();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < _filterFields; i++) ...[
        const _Field(),
        const SizedBox(height: Spacing.s12),
      ],
      const Row(
        children: [
          Expanded(child: _Field()),
          SizedBox(width: Spacing.s12),
          Expanded(child: _Field()),
        ],
      ),
    ],
  );
}

class _Field extends StatelessWidget {
  const _Field();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Skeleton(width: 96, height: _labelHeight),
      ),
      SizedBox(height: Spacing.s8),
      Skeleton(height: _boxHeight),
    ],
  );
}
