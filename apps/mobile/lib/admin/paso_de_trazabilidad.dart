import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class PasoDeTrazabilidad extends StatelessWidget {
  const PasoDeTrazabilidad({
    super.key,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$titulo, $subtitulo',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  subtitulo,
                  style: Textos.leyenda.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
