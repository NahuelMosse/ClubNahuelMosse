// kit-shape: the widget, its State and the delayed curve are a single Flutter piece
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'timings.dart';

/// Makes [child] appear with a fade, shifted, scaled and rotated, until it settles in
/// place. Waits [delay] before starting.
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.entrance,
    this.fromX = 0,
    this.fromY = 20,
    this.scaleFrom = 1,
    this.turn = 0,
    this.curve = AppMotion.out,
    this.alreadyEntered = false,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double fromX;
  final double fromY;
  final double scaleFrom;

  /// Turns left to reach its position.
  final double turn;

  /// The curve of the shift, the scale and the turn; the fade is always easeOut.
  final Curve curve;

  /// Born in its final state, without animating: for a block that is rebuilt on a
  /// screen that already did its entrance.
  final bool alreadyEntered;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.delay + widget.duration,
  );
  late final double _begin =
      widget.delay.inMicroseconds /
      (widget.delay + widget.duration).inMicroseconds;
  late final Animation<double> _progress = _controller.drive(
    CurveTween(curve: _Delayed(_begin, AppMotion.out)),
  );
  late final Animation<double> _travel = _controller.drive(
    CurveTween(curve: _Delayed(_begin, widget.curve)),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.alreadyEntered) {
      _controller.value = 1;
    } else {
      startOnce(_controller, context);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _progress,
    alwaysIncludeSemantics: true,
    child: AnimatedBuilder(
      animation: _travel,
      child: widget.child,
      builder: (context, child) {
        final remaining = 1 - _travel.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(
            widget.fromX * remaining,
            widget.fromY * remaining,
            0,
          )..multiply(Matrix4.rotationZ(widget.turn * remaining * 2 * math.pi)),
          child: Transform.scale(
            scale: widget.scaleFrom + (1 - widget.scaleFrom) * _travel.value,
            child: child,
          ),
        );
      },
    ),
  );
}

/// [curve] from [begin] to the end; before [begin] it is exactly 0, without the noise of
/// the cubic curves' approximation.
class _Delayed extends Curve {
  const _Delayed(this.begin, this.curve);

  final double begin;
  final Curve curve;

  @override
  double transformInternal(double t) {
    final x = (t - begin) / (1 - begin);
    if (x <= 1e-6) return 0;
    if (x >= 1) return 1;
    return curve.transform(x);
  }
}
