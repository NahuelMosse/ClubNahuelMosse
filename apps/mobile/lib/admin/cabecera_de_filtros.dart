import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El título del panel de filtros y su botón de cerrar.
class CabeceraDeFiltros extends StatelessWidget {
  const CabeceraDeFiltros({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s24,
        Medidas.s16,
        Medidas.s16,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Filtros',
                style: Textos.h2.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
            icon: const Icon(Icons.close_rounded),
            color: p.textSecondary,
          ),
        ],
      ),
    );
  }
}
