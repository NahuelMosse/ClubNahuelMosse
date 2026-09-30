import 'package:flutter/material.dart';

import '../reservas/reservas.dart';
import '../tema/tema.dart';
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
      EstadoDeReserva.anulada || EstadoDeReserva.cancelada => (
        p.stateDangerMuted,
        p.stateDangerInk,
      ),
      EstadoDeReserva.completada => (p.bgSurface, p.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s8,
        vertical: Medidas.s4,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Text(
        estado.name.toUpperCase(),
        style: Textos.sobretitulo.copyWith(color: tinta),
      ),
    );
  }
}
