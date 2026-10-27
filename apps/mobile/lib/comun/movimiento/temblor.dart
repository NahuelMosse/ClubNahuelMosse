// kit-shape: el widget y su State son una sola pieza de Flutter
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tiempos.dart';

/// Sacude a [child] de lado a lado una vez cada vez que [disparador] pasa a un valor
/// no nulo distinto del anterior.
class Temblor extends StatefulWidget {
  const Temblor({super.key, required this.disparador, required this.child});

  final Object? disparador;
  final Widget child;

  @override
  State<Temblor> createState() => _TemblorState();
}

class _TemblorState extends State<Temblor> with SingleTickerProviderStateMixin {
  static const _puntos = [0.0, -9.0, 9.0, -6.0, 6.0, -3.0, 0.0];

  late final _controlador = AnimationController(
    vsync: this,
    duration: Movimiento.temblor,
  );

  @override
  void didUpdateWidget(Temblor anterior) {
    super.didUpdateWidget(anterior);
    final disparador = widget.disparador;
    if (disparador == null || disparador == anterior.disparador) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controlador.forward(from: 0));
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  double _desplazamiento(double avance) {
    final tramos = _puntos.length - 1;
    final i = math.min((avance * tramos).floor(), tramos - 1);
    final fraccion = avance * tramos - i;
    return _puntos[i] + (_puntos[i + 1] - _puntos[i]) * fraccion;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controlador,
    child: widget.child,
    builder: (context, hijo) => Transform.translate(
      offset: Offset(_desplazamiento(_controlador.value), 0),
      child: hijo,
    ),
  );
}
