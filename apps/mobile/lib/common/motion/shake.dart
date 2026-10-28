// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
// kit-shape: the widget and its State are a single Flutter piece
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'timings.dart';

/// Shakes [child] from side to side once each time [trigger] changes to a non-null value
/// different from the previous one.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  static const _points = [0.0, -9.0, 9.0, -6.0, 6.0, -3.0, 0.0];

  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.shake,
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trigger = widget.trigger;
    if (trigger == null || trigger == oldWidget.trigger) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _offset(double progress) {
    final segments = _points.length - 1;
    final i = math.min((progress * segments).floor(), segments - 1);
    final fraction = progress * segments - i;
    return _points[i] + (_points[i + 1] - _points[i]) * fraction;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      offset: Offset(_offset(_controller.value), 0),
      child: child,
    ),
  );
}
