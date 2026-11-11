// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Ticket separator: a dotted line, decorative.
class DieCut extends StatelessWidget {
  const DieCut({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ExcludeSemantics(
      child: SizedBox(
        height: 16,
        width: double.infinity,
        child: CustomPaint(painter: DieCutPainter(line: p.borderControl)),
      ),
    );
  }
}

/// Paints the dotted line of the [DieCut].
class DieCutPainter extends CustomPainter {
  const DieCutPainter({required this.line});

  final Color line;

  static const _margin = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = line;
    final limit = size.width - _margin;
    var x = _margin;
    while (x < limit) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 6).clamp(0.0, limit), y),
        stroke,
      );
      x += 10;
    }
  }

  @override
  bool shouldRepaint(DieCutPainter oldDelegate) => oldDelegate.line != line;
}
