import 'package:flutter/material.dart';
import '../comun/insignia.dart';
import '../tema/tokens.dart';
import 'reservas.dart';

/// `Badge-Estado`.
class EtiquetaDeEstado extends StatelessWidget {
  const EtiquetaDeEstado({super.key, required this.estado});

  final EstadoDeReserva estado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, tinta) = switch (estado) {
      EstadoDeReserva.activa => (p.bgSurface, p.stateSuccessInk),
      EstadoDeReserva.anulada => (p.stateDangerMuted, p.stateDangerInk),
      _ => (p.bgSurface, p.textSecondary),
    };
    return InsigniaDeEstado(
      texto: estado.name.toUpperCase(),
      fondo: fondo,
      tinta: tinta,
    );
  }
}
