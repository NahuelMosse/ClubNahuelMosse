// kit-shape: the widget and its State are a single Flutter piece
import 'dart:async';

import 'package:flutter/material.dart';

import 'timings.dart';

/// Shrinks [child] to 0.97 while a finger presses it. It does not take the gesture: what is
/// inside keeps receiving it.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child});

  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: AppMotion.press,
  );
  late final Animation<double> _scale = _controller.drive(
    Tween<double>(begin: 1, end: 0.97).chain(CurveTween(curve: AppMotion.out)),
  );
  int _fingers = 0;

  void _down() {
    _fingers++;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controller.forward());
  }

  void _up() {
    if (!mounted) return;
    if (_fingers > 0) _fingers--;
    if (_fingers == 0) unawaited(_controller.reverse());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _down(),
    onPointerUp: (_) => _up(),
    onPointerCancel: (_) => _up(),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}
