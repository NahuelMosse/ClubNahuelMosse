import 'package:flutter/material.dart';

import '../../../common/skeleton.dart';
import '../../../theme/tokens.dart';

/// Las tarjetas de aviso mientras llegan: una etiqueta de día y marcos con la forma de
/// `NoticeCard`, tantos como llenan la pantalla.
class NoticeCardSkeleton extends StatelessWidget {
  const NoticeCardSkeleton({super.key});

  static const _frames = 10;
  static const _iconSize = 40.0;

  @override
  Widget build(BuildContext context) => SkeletonZone(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Spacing.s24,
        Spacing.s8,
        Spacing.s24,
        Spacing.s40,
      ),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: Spacing.s8, bottom: Spacing.s12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Skeleton(width: 80, height: 12),
          ),
        ),
        for (var i = 0; i < _frames; i++) ...[
          const _Frame(),
          const SizedBox(height: Spacing.s12),
        ],
      ],
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('skeleton-card'),
    padding: const EdgeInsets.all(Spacing.s12),
    decoration: BoxDecoration(
      border: Border.all(color: context.palette.borderDefault),
      borderRadius: BorderRadius.circular(Spacing.radiusLg),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton(
          width: NoticeCardSkeleton._iconSize,
          height: NoticeCardSkeleton._iconSize,
        ),
        SizedBox(width: Spacing.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 140, height: 12),
              SizedBox(height: Spacing.s4),
              Skeleton(height: 18),
              SizedBox(height: Spacing.s4),
              Skeleton(width: 200, height: 16),
            ],
          ),
        ),
      ],
    ),
  );
}
