import 'package:flutter/material.dart';

import '../reservas/reservas.dart';
import '../tema/tokens.dart';
import 'chip_de_filtro.dart';

/// «Todas» y los estados de una reserva; [alElegir] recibe el tocado, o `null` por «Todas».
class FiltroDeEstado extends StatelessWidget {
  const FiltroDeEstado({
    super.key,
    required this.elegido,
    required this.alElegir,
  });

  final EstadoDeReserva? elegido;
  final ValueChanged<EstadoDeReserva?> alElegir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Medidas.s8,
      runSpacing: Medidas.s8,
      children: [
        ChipDeFiltro(
          texto: 'Todas',
          alTocar: () => alElegir(null),
          elegido: elegido == null,
        ),
        for (final e in const [
          EstadoDeReserva.activa,
          EstadoDeReserva.completada,
          EstadoDeReserva.anulada,
        ])
          ChipDeFiltro(
            texto: switch (e) {
              EstadoDeReserva.activa => 'Activas',
              EstadoDeReserva.completada => 'Completadas',
              _ => 'Anuladas',
            },
            alTocar: () => alElegir(e),
            elegido: elegido == e,
          ),
      ],
    );
  }
}
