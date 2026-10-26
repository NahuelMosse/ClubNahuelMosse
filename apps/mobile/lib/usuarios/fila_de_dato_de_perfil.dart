import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

class FilaDeDatoDePerfil extends StatelessWidget {
  const FilaDeDatoDePerfil({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.fija = false,
  });

  final String etiqueta;
  final String valor;
  final bool fija;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final mostrado = valor.trim().isEmpty ? '—' : valor;
    return Semantics(
      container: true,
      label: fija
          ? '$etiqueta: $mostrado. No se puede cambiar'
          : '$etiqueta: $mostrado',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s12),
        child: Row(
          children: [
            Text(etiqueta, style: Textos.leyenda.copyWith(color: p.textMuted)),
            const SizedBox(width: Medidas.s12),
            Expanded(
              child: Text(
                mostrado,
                textAlign: TextAlign.right,
                style: Textos.cuerpoFuerte.copyWith(
                  color: fija ? p.textMuted : p.textPrimary,
                ),
              ),
            ),
            if (fija) ...[
              const SizedBox(width: Medidas.s8),
              Icon(Icons.lock_outline_rounded, size: 15, color: p.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
