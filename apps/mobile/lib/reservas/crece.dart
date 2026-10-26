import 'dart:async';
import 'package:flutter/material.dart';
import '../comun/movimiento.dart';

/// Crece de 0,88 a 1 con rebote cada vez que [activo] pasa de falso a verdadero.
class Crece extends StatefulWidget {
  const Crece({super.key, required this.activo, required this.child});

  final bool activo;
  final Widget child;

  @override
  State<Crece> createState() => _CreceState();
}

class _CreceState extends State<Crece> with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late final Animation<double> _escala = _controlador.drive(
    Tween<double>(
      begin: 0.88,
      end: 1,
    ).chain(CurveTween(curve: Movimiento.rebote)),
  );

  @override
  void didUpdateWidget(Crece anterior) {
    super.didUpdateWidget(anterior);
    if (!widget.activo || anterior.activo) return;
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
