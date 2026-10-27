import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El emoji y el nombre del deporte al pie de un [TileDeporte].
class PieDeTile extends StatelessWidget {
  const PieDeTile({super.key, required this.emoji, required this.nombre});

  final String emoji;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Textos.titulo.copyWith(color: p.textOnMedia),
        ),
      ],
    );
  }
}
