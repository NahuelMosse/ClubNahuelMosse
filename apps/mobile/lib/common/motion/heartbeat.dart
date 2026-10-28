// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
// kit-shape: the widget and its State are a single Flutter piece
import 'dart:async';

import 'package:flutter/material.dart';

import 'timings.dart';

/// Makes [child] beat (scale 1 → 1.03 → 1) each time [trigger] changes to a non-null value
/// different from the previous one.
class Heartbeat extends StatefulWidget {
  const Heartbeat({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<Heartbeat> createState() => _HeartbeatState();
}

class _HeartbeatState extends State<Heartbeat>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.heartbeat,
  );
  late final Animation<double> _scale = _controller.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.03,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]),
  );

  @override
  void didUpdateWidget(Heartbeat oldWidget) {
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

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}
