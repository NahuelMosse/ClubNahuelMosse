import 'package:flutter/material.dart';

import '../tema/tokens.dart';

export 'esqueleto_de_lista.dart';
export 'zona_de_esqueletos.dart';

/// Un bloque gris redondeado: el lugar de algo que todavía no llegó.
class Esqueleto extends StatelessWidget {
  const Esqueleto({
    super.key,
    this.width,
    required this.alto,
    this.radio = Medidas.radioMd,
  });

  final double? width;
  final double alto;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: alto,
      decoration: BoxDecoration(
        color: oscuro ? p.bgSurfaceRaised : p.bgSurface,
        borderRadius: BorderRadius.circular(radio),
      ),
    );
  }
}
