import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'isotipo.dart';

/// La fila de arriba de la ficha: «FICHA DE SOCIO», el número si lo hay y el isotipo.
class CabeceraDeFicha extends StatelessWidget {
  const CabeceraDeFicha({super.key, this.numero});

  final String? numero;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final nro = numero;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FICHA DE SOCIO',
              style: Textos.sobretitulo.copyWith(color: p.accentOnMedia),
            ),
            if (nro != null)
              Text(nro, style: Textos.mono.copyWith(color: p.textOnMediaMuted)),
          ],
        ),
        const Spacer(),
        const Isotipo(tamano: 32, decorativo: true),
      ],
    );
  }
}
