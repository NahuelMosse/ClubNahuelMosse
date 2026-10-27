import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La etiqueta «ELEGIDO» que marca un [TileDeporte] con el acento.
class InsigniaElegido extends StatelessWidget {
  const InsigniaElegido({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: p.accentBase,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Text(
        'ELEGIDO',
        style: Textos.sobretitulo.copyWith(color: p.accentOn),
      ),
    );
  }
}
