import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La etiqueta de deporte sobre la portada: borde claro sobre la foto.
class EtiquetaClara extends StatelessWidget {
  const EtiquetaClara({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s8,
        vertical: Medidas.s4,
      ),
      decoration: BoxDecoration(
        color: const Color(0x99000000),
        borderRadius: BorderRadius.circular(Medidas.radioPill),
        border: Border.all(color: const Color(0x66FFFFFF)),
      ),
      child: Text(texto, style: Textos.leyenda.copyWith(color: p.textOnMedia)),
    );
  }
}
