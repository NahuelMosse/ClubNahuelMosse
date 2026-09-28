import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Tag`: etiqueta informativa de 26 de alto. [sobreFoto] la hace lima sólida, porque el
/// translúcido no contrasta encima de una foto.
class Etiqueta extends StatelessWidget {
  const Etiqueta({
    super.key,
    required this.texto,
    this.icono,
    this.sobreFoto = false,
  });

  final String texto;
  final IconData? icono;
  final bool sobreFoto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, tinta) = sobreFoto
        ? (Paleta.oscura.accentBase, Paleta.oscura.accentOn)
        : (p.bgSurfaceRaised, p.textSecondary);
    final simbolo = icono;
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: Medidas.s8),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (simbolo != null) ...[
            Icon(simbolo, size: 14, color: tinta),
            const SizedBox(width: Medidas.s4),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Textos.leyenda.copyWith(color: tinta),
            ),
          ),
        ],
      ),
    );
  }
}
