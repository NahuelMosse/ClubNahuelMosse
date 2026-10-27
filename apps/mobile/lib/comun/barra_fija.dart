import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// La barra fija al pie de una pantalla: fondo [color], borde arriba y el área segura.
class BarraFija extends StatelessWidget {
  const BarraFija({
    super.key,
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: Medidas.s24,
      vertical: Medidas.s16,
    ),
  });

  final Color color;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
