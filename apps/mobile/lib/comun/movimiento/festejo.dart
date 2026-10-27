// kit-shape: el widget, su State y el pintor de los aros son una sola pieza de Flutter
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../tema/tokens.dart';
import 'aparecer.dart';
import 'tiempos.dart';

/// El festejo de la reserva confirmada: un aro punteado que gira y chispas alrededor del
/// [centro], el [grito] que crece debajo y, después, el [comprobante]. Corre una vez.
class Festejo extends StatefulWidget {
  const Festejo({
    super.key,
    required this.centro,
    required this.grito,
    required this.comprobante,
  });

  final Widget centro;
  final Widget grito;
  final Widget comprobante;

  @override
  State<Festejo> createState() => _FestejoState();
}

class _FestejoState extends State<Festejo> with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 2300);
  static const _inicioChispas = Duration(milliseconds: 370);
  static const _duracionChispas = Duration(milliseconds: 450);
  static const _inicioGrito = Duration(milliseconds: 420);
  static const _duracionGrito = Duration(milliseconds: 500);
  static const _inicioComprobante = Duration(milliseconds: 870);
  static const _duracionComprobante = Duration(milliseconds: 700);
  static const _lado = 240.0;
  static const _radio = 108.0;

  late final _controlador = AnimationController(vsync: this, duration: _total);
  bool _arrancado = false;

  double _fraccion(Duration d) => d.inMicroseconds / _total.inMicroseconds;

  Interval _tramo(
    Duration inicio,
    Duration duracion, [
    Curve curva = Curves.linear,
  ]) => Interval(_fraccion(inicio), _fraccion(inicio + duracion), curve: curva);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;
    arrancarUnaVez(_controlador, context);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  Animation<double> get _chispa => _controlador.drive(
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
    ]).chain(CurveTween(curve: _tramo(_inicioChispas, _duracionChispas))),
  );

  /// El aro que gira, las chispas y el [centro], apilados.
  Widget _escenario(Paleta p) {
    final giro = _controlador.drive(
      Tween<double>(
        begin: 0,
        end: -1 / 3,
      ).chain(CurveTween(curve: Movimiento.salida)),
    );
    final chispa = _chispa;
    return SizedBox(
      width: _lado,
      height: _lado,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: RotationTransition(
              turns: giro,
              child: CustomPaint(
                size: const Size.square(_lado),
                painter: _Aro(p.accentBase, _radio),
              ),
            ),
          ),
          for (var i = 0; i < 8; i++)
            ExcludeSemantics(
              child: Transform.translate(
                offset: Offset.fromDirection(
                  i * math.pi / 4 + math.pi / 8,
                  _radio + (i.isEven ? 6 : -2),
                ),
                child: ScaleTransition(
                  scale: chispa,
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
          widget.centro,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gritoEscala = _controlador.drive(
      Tween<double>(begin: 0.55, end: 1).chain(
        CurveTween(
          curve: _tramo(_inicioGrito, _duracionGrito, Movimiento.rebote),
        ),
      ),
    );
    final gritoOpacidad = _controlador.drive(
      CurveTween(
        curve: _tramo(
          _inicioGrito,
          const Duration(milliseconds: 200),
          Movimiento.salida,
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _escenario(context.paleta),
        const SizedBox(height: Medidas.s8),
        FadeTransition(
          opacity: gritoOpacidad,
          alwaysIncludeSemantics: true,
          child: ScaleTransition(scale: gritoEscala, child: widget.grito),
        ),
        const SizedBox(height: Medidas.s12),
        Aparecer(
          retraso: _inicioComprobante,
          duracion: _duracionComprobante,
          desdeY: 24,
          child: widget.comprobante,
        ),
      ],
    );
  }
}

/// Un aro de rayitas alrededor del centro.
class _Aro extends CustomPainter {
  _Aro(this.trazo, this.radio);

  final Color trazo;
  final double radio;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final linea = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = trazo;
    const rayas = 48;
    for (var i = 0; i < rayas; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio),
        i * 2 * math.pi / rayas,
        math.pi / rayas,
        false,
        linea,
      );
    }
  }

  @override
  bool shouldRepaint(_Aro anterior) =>
      anterior.trazo != trazo || anterior.radio != radio;
}
