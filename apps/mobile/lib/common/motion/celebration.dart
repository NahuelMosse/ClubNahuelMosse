// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
// kit-shape: the widget, its State and the rings painter are a single Flutter piece
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/tokens.dart';
import 'fade_in.dart';
import 'timings.dart';

/// The celebration of the confirmed booking: a spinning dotted ring and sparks around the
/// [center], the [cheer] that grows below and, after that, the [receipt]. Runs once.
class Celebration extends StatefulWidget {
  const Celebration({
    super.key,
    required this.center,
    required this.cheer,
    required this.receipt,
  });

  final Widget center;
  final Widget cheer;
  final Widget receipt;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2300);
  static const _sparksStart = Duration(milliseconds: 370);
  static const _sparksDuration = Duration(milliseconds: 450);
  static const _cheerStart = Duration(milliseconds: 420);
  static const _cheerDuration = Duration(milliseconds: 500);
  static const _receiptStart = Duration(milliseconds: 870);
  static const _receiptDuration = Duration(milliseconds: 700);
  static const _side = 240.0;
  static const _radius = 108.0;

  late final _controller = AnimationController(vsync: this, duration: _total);
  bool _started = false;

  double _fraction(Duration d) => d.inMicroseconds / _total.inMicroseconds;

  Interval _span(
    Duration start,
    Duration duration, [
    Curve curve = Curves.linear,
  ]) => Interval(_fraction(start), _fraction(start + duration), curve: curve);

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

  Animation<double> get _spark => _controller.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1.6,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.6,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).chain(CurveTween(curve: _span(_sparksStart, _sparksDuration))),
  );

  /// The spinning ring, the sparks and the [center], stacked.
  Widget _stage(Palette p) {
    final turn = _controller.drive(
      Tween<double>(
        begin: 0,
        end: -1 / 3,
      ).chain(CurveTween(curve: AppMotion.out)),
    );
    final spark = _spark;
    return SizedBox(
      width: _side,
      height: _side,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: RotationTransition(
              turns: turn,
              child: CustomPaint(
                size: const Size.square(_side),
                painter: _Ring(p.accentBase, _radius),
              ),
            ),
          ),
          for (var i = 0; i < 8; i++)
            ExcludeSemantics(
              child: Transform.translate(
                offset: Offset.fromDirection(
                  i * math.pi / 4 + math.pi / 8,
                  _radius + (i.isEven ? 6 : -2),
                ),
                child: ScaleTransition(
                  scale: spark,
                  child: Container(
                    width: i.isEven ? 8 : 5,
                    height: i.isEven ? 8 : 5,
                    decoration: BoxDecoration(
                      color: p.accentBase,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          widget.center,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cheerScale = _controller.drive(
      Tween<double>(begin: 0.55, end: 1).chain(
        CurveTween(curve: _span(_cheerStart, _cheerDuration, AppMotion.bounce)),
      ),
    );
    final cheerOpacity = _controller.drive(
      CurveTween(
        curve: _span(
          _cheerStart,
          const Duration(milliseconds: 200),
          AppMotion.out,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stage(context.palette),
        const SizedBox(height: Spacing.s8),
        FadeTransition(
          opacity: cheerOpacity,
          alwaysIncludeSemantics: true,
          child: ScaleTransition(scale: cheerScale, child: widget.cheer),
        ),
        const SizedBox(height: Spacing.s12),
        FadeIn(
          delay: _receiptStart,
          duration: _receiptDuration,
          fromY: 24,
          child: widget.receipt,
        ),
      ],
    );
  }
}

/// A ring of little dashes around the center.
class _Ring extends CustomPainter {
  _Ring(this.stroke, this.radius);

  final Color stroke;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = stroke;
    const dashes = 48;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * 2 * math.pi / dashes,
        math.pi / dashes,
        false,
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring oldDelegate) =>
      oldDelegate.stroke != stroke || oldDelegate.radius != radius;
}
