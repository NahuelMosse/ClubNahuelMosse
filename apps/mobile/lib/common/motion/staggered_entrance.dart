import 'package:flutter/material.dart';

import 'fade_in.dart';
import 'timings.dart';

/// Makes [children] appear one after another: the first at [start] and each next one [step]
/// after the previous.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    super.key,
    required this.children,
    this.start = Duration.zero,
    this.step = AppMotion.step,
    this.duration = AppMotion.entrance,
    this.fromY = 20,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final Duration start;
  final Duration step;
  final Duration duration;
  final double fromY;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    children: [
      for (var i = 0; i < children.length; i++)
        FadeIn(
          delay: start + step * i,
          duration: duration,
          fromY: fromY,
          child: children[i],
        ),
    ],
  );
}
