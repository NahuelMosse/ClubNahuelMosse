import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Separador de entrada: línea punteada con una muesca a cada lado, de adorno.
class Troquel extends StatelessWidget {
  const Troquel({super.key, required this.fondo});

  /// Color de lo que hay detrás, con el que se rellenan las muescas.
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ExcludeSemantics(
      child: SizedBox(
        height: 16,
        width: double.infinity,
        child: CustomPaint(
          painter: PintorTroquel(linea: p.borderControl, fondo: fondo),
        ),
      ),
    );
  }
}

/// Pinta la línea punteada y las dos muescas del [Troquel].
class PintorTroquel extends CustomPainter {
  const PintorTroquel({
    required this.linea,
    required this.fondo,
    this.diametroMuesca = 16,
  });

  final Color linea;
  final Color fondo;
  final double diametroMuesca;

  @override
  void paint(Canvas canvas, Size size) {
    final radio = diametroMuesca / 2;
    final y = size.height / 2;
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = linea;
    final limite = size.width - radio - 4;
    var x = radio + 4;
    while (x < limite) {
      canvas.drawLine(
        Offset(x, y),
        Offset((x + 6).clamp(0.0, limite), y),
        trazo,
      );
      x += 10;
    }
    final muesca = Paint()..color = fondo;
    canvas.drawCircle(Offset(0, y), radio, muesca);
    canvas.drawCircle(Offset(size.width, y), radio, muesca);
  }

  @override
  bool shouldRepaint(PintorTroquel anterior) =>
      anterior.linea != linea ||
      anterior.fondo != fondo ||
      anterior.diametroMuesca != diametroMuesca;
}
