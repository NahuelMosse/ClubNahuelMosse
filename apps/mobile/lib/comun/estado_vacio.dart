import 'package:flutter/material.dart';

import '../tema/tema.dart';
import 'boton.dart';
import '../tema/tokens.dart';

/// `Empty-State`: ícono en círculo, título y texto, en lugar de un listado vacío.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.titulo,
    required this.texto,
    this.accion,
    this.alTocar,
    this.icono = Icons.grid_view_outlined,
  });

  final String titulo;
  final String texto;
  final String? accion;
  final VoidCallback? alTocar;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Medidas.s40),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: p.bgSurfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, size: 28, color: p.textMuted),
          ),
          const SizedBox(height: Medidas.s16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: Textos.titulo.copyWith(color: p.textPrimary),
          ),
          const SizedBox(height: Medidas.s8),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: Textos.leyenda.copyWith(color: p.textMuted),
          ),
          if (accion case final texto?) ...[
            const SizedBox(height: Medidas.s8),
            BotonTexto(texto: texto, alTocar: alTocar),
          ],
        ],
      ),
    );
  }
}
