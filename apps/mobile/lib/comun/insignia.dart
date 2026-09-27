import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Badge-Estado` del prototipo, en su variante lima: «MIEMBRO ACTIVO», «ACTIVA».
class Insignia extends StatelessWidget {
  const Insignia({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s12,
        vertical: Medidas.s4,
      ),
      decoration: BoxDecoration(
        color: p.accentMuted,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Text(
        texto,
        style: Textos.sobretitulo.copyWith(color: p.accentInk),
      ),
    );
  }
}
