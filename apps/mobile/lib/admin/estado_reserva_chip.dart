import 'package:flutter/material.dart';

import '../comun/insignia.dart';
import '../reservas/reservas.dart';
import '../tema/tokens.dart';

/// `Badge-Estado` del historial admin: mismo código de color que «Mis reservas».
class EstadoReservaChip extends StatelessWidget {
  const EstadoReservaChip({super.key, required this.estado});

  final EstadoDeReserva estado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, tinta) = switch (estado) {
      EstadoDeReserva.activa => (p.stateSuccessMuted, p.stateSuccessInk),
      EstadoDeReserva.anulada ||
      EstadoDeReserva.cancelada => (p.stateDangerMuted, p.stateDangerInk),
      EstadoDeReserva.completada => (p.bgSurface, p.textSecondary),
    };
    return InsigniaDeEstado(
      texto: estado.name.toUpperCase(),
      fondo: fondo,
      tinta: tinta,
    );
  }
}
