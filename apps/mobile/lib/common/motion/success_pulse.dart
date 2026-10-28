// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
// kit-shape: the widget, its State and the reveal clip are a single Flutter piece
import 'package:flutter/material.dart';

import 'timings.dart';

/// The circle of a result: grows from 0.4 to 1 with a bounce and, from 170 ms on, reveals
/// the icon with an opening clip.
class SuccessPulse extends StatefulWidget {
  const SuccessPulse({
    super.key,
    required this.icon,
    required this.background,
    required this.ink,
    this.diameter = 96,
    this.iconSize = 40,
  });

  final IconData icon;
  final Color background;
  final Color ink;
  final double diameter;
  final double iconSize;

  @override
  State<SuccessPulse> createState() => _SuccessPulseState();
}

class _SuccessPulseState extends State<SuccessPulse>
    with SingleTickerProviderStateMixin {
  static const _scaleDuration = Duration(milliseconds: 550);
  static const _iconStart = Duration(milliseconds: 170);
  static const _iconDuration = Duration(milliseconds: 450);
  static const _total = Duration(milliseconds: 620);

  late final _controller = AnimationController(vsync: this, duration: _total);
  late final Animation<double> _size = _controller.drive(
    Tween<double>(begin: 0.4, end: 1).chain(
      CurveTween(
        curve: Interval(
          0,
          _scaleDuration.inMicroseconds / _total.inMicroseconds,
          curve: AppMotion.bounce,
        ),
      ),
    ),
  );
  late final Animation<double> _reveal = _controller.drive(
    CurveTween(
      curve: Interval(
        _iconStart.inMicroseconds / _total.inMicroseconds,
        (_iconStart + _iconDuration).inMicroseconds / _total.inMicroseconds,
        curve: AppMotion.out,
      ),
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    startOnce(_controller, context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _size,
    child: Container(
      width: widget.diameter,
      height: widget.diameter,
      decoration: BoxDecoration(
        color: widget.background,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _reveal,
        builder: (context, _) => ClipPath(
          clipper: _Reveal(_reveal.value),
          child: Icon(widget.icon, size: widget.iconSize, color: widget.ink),
        ),
      ),
    ),
  );
}

/// A circle from the center that grows until it covers the whole icon.
class _Reveal extends CustomClipper<Path> {
  _Reveal(this.progress);

  final double progress;

  @override
  Path getClip(Size size) => Path()
    ..addOval(
      Rect.fromCircle(
        center: size.center(Offset.zero),
        radius: progress * size.longestSide * 0.75,
      ),
    );

  @override
  bool shouldReclip(_Reveal oldClipper) => oldClipper.progress != progress;
}
