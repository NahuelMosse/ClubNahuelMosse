import 'dart:async';

import 'package:flutter/material.dart';

import 'tiempos.dart';

/// Achica a [child] a 0,97 mientras un dedo lo presiona. No toma el gesto: lo que haya
/// adentro sigue recibiéndolo.
class Presionable extends StatefulWidget {
  const Presionable({super.key, required this.child});

  final Widget child;

  @override
  State<Presionable> createState() => _PresionableState();
}

class _PresionableState extends State<Presionable>
    with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: Movimiento.presion,
  );
  late final Animation<double> _escala = _controlador.drive(
    Tween<double>(
      begin: 1,
      end: 0.97,
    ).chain(CurveTween(curve: Movimiento.salida)),
  );
  int _dedos = 0;

  void _bajar() {
    _dedos++;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controlador.forward());
  }

  void _subir() {
    if (!mounted) return;
    if (_dedos > 0) _dedos--;
    if (_dedos == 0) unawaited(_controlador.reverse());
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _bajar(),
    onPointerUp: (_) => _subir(),
    onPointerCancel: (_) => _subir(),
    child: ScaleTransition(scale: _escala, child: widget.child),
  );
}
