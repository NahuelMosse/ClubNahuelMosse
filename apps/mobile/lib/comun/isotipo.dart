import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Isotipo del club: un escudo con una cancha estilizada adentro, en el color de acento.
class Isotipo extends StatelessWidget {
  const Isotipo({super.key, this.tamano = 64, this.decorativo = false});

  final double tamano;
  final bool decorativo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final dibujo = ExcludeSemantics(
      child: SizedBox(
        width: tamano,
        height: tamano,
        child: CustomPaint(painter: PintorIsotipo(color: p.accentBase)),
      ),
    );
    if (decorativo) return dibujo;
    return Semantics(label: 'Club Nahuel Mosse', image: true, child: dibujo);
  }
}

/// Dibuja el escudo y la pelota del [Isotipo] escalados al tamaño disponible.
class PintorIsotipo extends CustomPainter {
  const PintorIsotipo({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final e = size.width / 64;
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * e
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = color;
    final relleno = Paint()..color = color;

    final escudo = Path()
      ..moveTo(32 * e, 4 * e)
      ..lineTo(56 * e, 12 * e)
      ..lineTo(56 * e, 32 * e)
      ..quadraticBezierTo(56 * e, 50 * e, 32 * e, 60 * e)
      ..quadraticBezierTo(8 * e, 50 * e, 8 * e, 32 * e)
      ..lineTo(8 * e, 12 * e)
      ..close();
    canvas.drawPath(escudo, trazo);

    final centro = Offset(32 * e, 32 * e);
    canvas.drawCircle(centro, 14 * e, trazo);
    canvas.drawLine(Offset(18 * e, 32 * e), Offset(46 * e, 32 * e), trazo);
    canvas.drawLine(Offset(32 * e, 18 * e), Offset(32 * e, 24 * e), trazo);
    canvas.drawLine(Offset(32 * e, 40 * e), Offset(32 * e, 46 * e), trazo);
    canvas.drawCircle(centro, 3 * e, relleno);
  }

  @override
  bool shouldRepaint(PintorIsotipo anterior) => anterior.color != color;
}
