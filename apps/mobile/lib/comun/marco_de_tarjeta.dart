import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// El marco de una tarjeta: superficie elevada, borde y esquinas redondeadas.
class MarcoDeTarjeta extends StatelessWidget {
  const MarcoDeTarjeta({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: child,
    );
  }
}
