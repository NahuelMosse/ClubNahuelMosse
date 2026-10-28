import 'dart:async';
import 'package:flutter/material.dart';
import '../../../common/motion.dart';

/// Grow de 0,88 a 1 con rebote cada vez que [activo] pasa de falso a verdadero.
class Grow extends StatefulWidget {
  const Grow({super.key, required this.activo, required this.child});

  final bool activo;
  final Widget child;

  @override
  State<Grow> createState() => _GrowState();
}

class _GrowState extends State<Grow> with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late final Animation<double> _escala = _controlador.drive(
    Tween<double>(
      begin: 0.88,
      end: 1,
    ).chain(CurveTween(curve: AppMotion.bounce)),
  );

  @override
  void didUpdateWidget(Grow anterior) {
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
