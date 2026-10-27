import 'package:flutter/material.dart';

import '../comun/etiqueta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Los deportes de la sede y «Ver canchas».
class PieDeTarjetaSede extends StatelessWidget {
  const PieDeTarjetaSede({super.key, required this.deportes});

  final List<String> deportes;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.all(Medidas.s16),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: Medidas.s4,
              runSpacing: Medidas.s4,
              children: [for (final d in deportes) Etiqueta(texto: d)],
            ),
          ),
          const SizedBox(width: Medidas.s8),
          Text(
            'Ver canchas',
            style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: p.accentInk),
        ],
      ),
    );
  }
}
