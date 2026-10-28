import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Ticket separator: a dotted line with a notch on each side, decorative.
class DieCut extends StatelessWidget {
  const DieCut({super.key, required this.background});

  /// Color of what is behind, used to fill the notches.
  final Color background;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: SizedBox(
        height: 16,
        width: double.infinity,
        child: CustomPaint(
          painter: DieCutPainter(line: p.borderControl, background: background),
        ),
      ),
    );
  }
}

/// Paints the dotted line and the two notches of the [DieCut].
class DieCutPainter extends CustomPainter {
  const DieCutPainter({
    required this.line,
    required this.background,
    this.notchDiameter = 16,
  });

  final Color line;
  final Color background;
  final double notchDiameter;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = notchDiameter / 2;
    final y = size.height / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = line;
    final limit = size.width - radius - 4;
    var x = radius + 4;
    while (x < limit) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 6).clamp(0.0, limit), y),
        stroke,
      );
      x += 10;
    }
    final notch = Paint()..color = background;
    canvas.drawCircle(Offset(0, y), radius, notch);
    canvas.drawCircle(Offset(size.width, y), radius, notch);
  }

  @override
  bool shouldRepaint(DieCutPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.background != background ||
      oldDelegate.notchDiameter != notchDiameter;
}
