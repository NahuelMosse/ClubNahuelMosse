// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

/// Giant number drawn only with a stroke, decorative: the screen reader ignores it.
class GiantBib extends StatelessWidget {
  const GiantBib({
    super.key,
    required this.text,
    required this.size,
    required this.color,
  });

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final painter = BibPainter(text: text, size: size, color: color);
    return ExcludeSemantics(
      child: CustomPaint(size: painter.measure(), painter: painter),
    );
  }
}

/// Paints the outline of the [GiantBib] number with a [TextPainter].
class BibPainter extends CustomPainter {
  const BibPainter({
    required this.text,
    required this.size,
    required this.color,
  });

  final String text;
  final double size;
  final Color color;

  TextPainter _painter() => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Archivo Black',
        fontSize: size,
        letterSpacing: -4,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// Size the text takes up.
  Size measure() => _painter().size;

  @override
  void paint(Canvas canvas, Size canvasSize) =>
      _painter().paint(canvas, Offset.zero);

  @override
  bool shouldRepaint(BibPainter oldDelegate) =>
      oldDelegate.text != text ||
      oldDelegate.size != size ||
      oldDelegate.color != color;
}
