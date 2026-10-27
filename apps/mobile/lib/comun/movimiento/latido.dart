import 'dart:async';

import 'package:flutter/material.dart';

import 'tiempos.dart';

/// Hace latir a [child] (escala 1 → 1,03 → 1) cada vez que [disparador] cambia a un valor
/// no nulo distinto del anterior.
class Latido extends StatefulWidget {
  const Latido({super.key, required this.disparador, required this.child});

  final Object? disparador;
  final Widget child;

  @override
  State<Latido> createState() => _LatidoState();
}

class _LatidoState extends State<Latido> with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: Movimiento.latido,
  );
  late final Animation<double> _escala = _controlador.drive(
    TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.03,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.03,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]),
  );

  @override
  void didUpdateWidget(Latido anterior) {
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

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _escala, child: widget.child);
}
