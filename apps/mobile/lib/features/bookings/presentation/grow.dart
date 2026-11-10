// kit-shape: a screen or error family kept with its private parts.
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../common/motion.dart';

/// Grows from 0.88 to 1 with a bounce each time [active] goes from false to true.
class Grow extends StatefulWidget {
  const Grow({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<Grow> createState() => _GrowState();
}

class _GrowState extends State<Grow> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late final Animation<double> _scale = _controller.drive(
    Tween<double>(
      begin: 0.88,
      end: 1,
    ).chain(CurveTween(curve: AppMotion.bounce)),
  );

  @override
  void didUpdateWidget(Grow previous) {
    super.didUpdateWidget(previous);
    if (!widget.active || previous.active) return;
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
