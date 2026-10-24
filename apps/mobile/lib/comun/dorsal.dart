import 'package:flutter/material.dart';

/// Número gigante dibujado sólo con trazo, de adorno: el lector de pantalla lo ignora.
class DorsalGigante extends StatelessWidget {
  const DorsalGigante({
    super.key,
    required this.texto,
    required this.tamano,
    required this.color,
  });

  final String texto;
  final double tamano;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pintor = PintorDorsal(texto: texto, tamano: tamano, color: color);
    return ExcludeSemantics(
      child: CustomPaint(size: pintor.medir(), painter: pintor),
    );
  }
}

/// Pinta el contorno del número del [DorsalGigante] con un [TextPainter].
class PintorDorsal extends CustomPainter {
  const PintorDorsal({
    required this.texto,
    required this.tamano,
    required this.color,
  });

  final String texto;
  final double tamano;
  final Color color;

  TextPainter _pintor() => TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontFamily: 'Archivo Black',
        fontSize: tamano,
        letterSpacing: -4,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  /// Tamaño que ocupa el texto.
  Size medir() => _pintor().size;

  @override
  void paint(Canvas canvas, Size size) => _pintor().paint(canvas, Offset.zero);

  @override
  bool shouldRepaint(PintorDorsal anterior) =>
      anterior.texto != texto ||
      anterior.tamano != tamano ||
      anterior.color != color;
}
