import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class AvisoDeRegistro extends StatelessWidget {
  const AvisoDeRegistro({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.stateDangerMuted,
          borderRadius: BorderRadius.circular(Medidas.radioMd),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 20,
              color: p.stateDangerInk,
            ),
            const SizedBox(width: Medidas.s12),
            Expanded(
              child: Text(
                texto,
                style: Textos.cuerpoFuerte.copyWith(color: p.stateDangerInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
