// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The club's logo mark: a court seen from above with the club's N and the ball, in the
/// accent color.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 64,
    this.decorative = false,
    this.color,
  });

  final double size;
  final bool decorative;

  /// Color of the drawing; without it the palette accent is used.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final drawing = ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: LogoMarkPainter(color: color ?? p.accentBase),
        ),
      ),
    );
    if (decorative) return drawing;
    return Semantics(label: 'Club Nahuel Mosse', image: true, child: drawing);
  }
}

/// Draws the court, the N and the ball of the [LogoMark] on a 64 grid scaled to the
/// available size, with the measures of the Figma `Marca/Isotipo` component.
class LogoMarkPainter extends CustomPainter {
  const LogoMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final e = size.width / 64;
    final thin = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * e
      ..color = color;
    final thick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * e
      ..strokeCap = StrokeCap.round
      ..color = color;

    final court = RRect.fromLTRBR(
      3 * e,
      3 * e,
      61 * e,
      61 * e,
      Radius.circular(14 * e),
    );
    canvas.drawRRect(court, thin);
    canvas.drawLine(Offset(3 * e, 32 * e), Offset(12 * e, 32 * e), thin);
    canvas.drawLine(Offset(52 * e, 32 * e), Offset(61 * e, 32 * e), thin);

    final letterN = Path()
      ..moveTo(18 * e, 46 * e)
      ..lineTo(18 * e, 18 * e)
      ..lineTo(46 * e, 46 * e)
      ..lineTo(46 * e, 24 * e);
    canvas.drawPath(letterN, thick..strokeJoin = StrokeJoin.round);

    canvas.drawCircle(Offset(46 * e, 14 * e), 5 * e, Paint()..color = color);
  }

  @override
  bool shouldRepaint(LogoMarkPainter oldDelegate) => oldDelegate.color != color;
}
