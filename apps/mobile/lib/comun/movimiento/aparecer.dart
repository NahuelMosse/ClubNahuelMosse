// kit-shape: el widget, su State y la curva con retraso son una sola pieza de Flutter
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tiempos.dart';

/// Hace aparecer a [child] con un fundido, corrido de lugar, a escala y girado, hasta
/// quedar en su sitio. Espera [retraso] antes de empezar.
class Aparecer extends StatefulWidget {
  const Aparecer({
    super.key,
    required this.child,
    this.retraso = Duration.zero,
    this.duracion = Movimiento.entrada,
    this.desdeX = 0,
    this.desdeY = 20,
    this.escalaDesde = 1,
    this.giro = 0,
    this.curva = Movimiento.salida,
    this.yaEntro = false,
  });

  final Widget child;
  final Duration retraso;
  final Duration duracion;
  final double desdeX;
  final double desdeY;
  final double escalaDesde;

  /// Vueltas que le faltan para llegar a su posición.
  final double giro;

  /// La curva del desplazamiento, la escala y el giro; el fundido es siempre easeOut.
  final Curve curva;

  /// Nace en su estado final, sin animar: para un bloque que vuelve a armarse en una
  /// pantalla que ya hizo su entrada.
  final bool yaEntro;

  @override
  State<Aparecer> createState() => _AparecerState();
}

class _AparecerState extends State<Aparecer>
    with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: widget.retraso + widget.duracion,
  );
  late final double _comienzo =
      widget.retraso.inMicroseconds /
      (widget.retraso + widget.duracion).inMicroseconds;
  late final Animation<double> _avance = _controlador.drive(
    CurveTween(curve: _ConRetraso(_comienzo, Movimiento.salida)),
  );
  late final Animation<double> _recorrido = _controlador.drive(
    CurveTween(curve: _ConRetraso(_comienzo, widget.curva)),
  );
  bool _arrancado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;
    if (widget.yaEntro) {
      _controlador.value = 1;
    } else {
      arrancarUnaVez(_controlador, context);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _avance,
    alwaysIncludeSemantics: true,
    child: AnimatedBuilder(
      animation: _recorrido,
      child: widget.child,
      builder: (context, hijo) {
        final resto = 1 - _recorrido.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.translationValues(
            widget.desdeX * resto,
            widget.desdeY * resto,
            0,
          )..multiply(Matrix4.rotationZ(widget.giro * resto * 2 * math.pi)),
          child: Transform.scale(
            scale:
                widget.escalaDesde +
                (1 - widget.escalaDesde) * _recorrido.value,
            child: hijo,
          ),
        );
      },
    ),
  );
}

/// [curva] desde [comienzo] hasta el final; antes de [comienzo] vale 0 exacto, sin el
/// ruido de la aproximación de las curvas cúbicas.
class _ConRetraso extends Curve {
  const _ConRetraso(this.comienzo, this.curva);

  final double comienzo;
  final Curve curva;

  @override
  double transformInternal(double t) {
    final x = (t - comienzo) / (1 - comienzo);
    if (x <= 1e-6) return 0;
    if (x >= 1) return 1;
    return curva.transform(x);
  }
}
