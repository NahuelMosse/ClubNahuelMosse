import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// La barra del detalle: la flecha de volver y el título. [alVolver] en `null` la deshabilita.
class CabeceraDeDetalleReserva extends StatelessWidget {
  const CabeceraDeDetalleReserva({super.key, required this.alVolver});

  final VoidCallback? alVolver;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s8,
        Medidas.s16,
        Medidas.s24,
        Medidas.s8,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: alVolver,
            tooltip: 'Volver',
            icon: const Icon(Icons.arrow_back_rounded),
            color: p.textPrimary,
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Detalle de reserva',
                style: Textos.h2.copyWith(color: p.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
