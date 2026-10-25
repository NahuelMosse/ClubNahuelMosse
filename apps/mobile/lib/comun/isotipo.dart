import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// Isotipo del club: una cancha vista desde arriba con la N del club y la pelota, en el color de
/// acento.
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

/// Dibuja la cancha, la N y la pelota del [Isotipo] sobre una grilla de 64 escalada al tamaño
/// disponible, con las medidas del componente `Marca/Isotipo` del Figma.
class PintorIsotipo extends CustomPainter {
  const PintorIsotipo({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final e = size.width / 64;
    final fino = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * e
      ..color = color;
    final grueso = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * e
      ..strokeCap = StrokeCap.round
      ..color = color;

    final cancha = RRect.fromLTRBR(
      3 * e,
      3 * e,
      61 * e,
      61 * e,
      Radius.circular(14 * e),
    );
    canvas.drawRRect(cancha, fino);
    canvas.drawLine(Offset(3 * e, 32 * e), Offset(12 * e, 32 * e), fino);
    canvas.drawLine(Offset(52 * e, 32 * e), Offset(61 * e, 32 * e), fino);

    final ene = Path()
      ..moveTo(18 * e, 46 * e)
      ..lineTo(18 * e, 18 * e)
      ..lineTo(46 * e, 46 * e)
      ..lineTo(46 * e, 24 * e);
    canvas.drawPath(ene, grueso..strokeJoin = StrokeJoin.round);

    canvas.drawCircle(Offset(46 * e, 14 * e), 5 * e, Paint()..color = color);
  }

  @override
  bool shouldRepaint(PintorIsotipo anterior) => anterior.color != color;
}
