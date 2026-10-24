import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Una cifra grande con su rótulo, para el [Marcador].
class CeldaMarcador {
  const CeldaMarcador({
    required this.cifra,
    required this.rotulo,
    this.destacada = false,
  });

  final String cifra;
  final String rotulo;
  final bool destacada;
}

/// Tablero de cifras sobre foto: vidrio oscuro con borde de acento y una celda por dato.
class Marcador extends StatelessWidget {
  const Marcador({super.key, required this.celdas});

  final List<CeldaMarcador> celdas;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.bgScrim.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.accentBase, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  for (var i = 0; i < celdas.length; i++) ...[
                    if (i > 0)
                      Container(width: 1, height: 40, color: p.borderDefault),
                    Expanded(child: _Celda(celda: celdas[i])),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Celda extends StatelessWidget {
  const _Celda({required this.celda});

  final CeldaMarcador celda;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      label: '${celda.cifra} ${celda.rotulo.toLowerCase()}',
      container: true,
      child: ExcludeSemantics(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              celda.cifra,
              style: TextStyle(
                fontFamily: 'Archivo Black',
                fontSize: 28,
                letterSpacing: -1,
                height: 1.2,
                color: celda.destacada ? p.accentOnMedia : p.textOnMedia,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              celda.rotulo.toUpperCase(),
              style: Textos.sobretitulo.copyWith(color: p.textOnMediaMuted),
            ),
          ],
        ),
      ),
    );
  }
}
