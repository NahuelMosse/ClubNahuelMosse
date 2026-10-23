import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El día y el horario de una reserva, con su ícono cada uno; los dos van en la misma línea
/// y pasan a la siguiente si no entran.
class FechaYHorario extends StatelessWidget {
  const FechaYHorario({
    super.key,
    required this.fecha,
    required this.horario,
    this.separacionVertical = Medidas.s8,
    this.alineacion = WrapCrossAlignment.center,
  });

  final String fecha;
  final String horario;

  /// El espacio entre las dos líneas cuando no entran juntos.
  final double separacionVertical;
  final WrapCrossAlignment alineacion;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Wrap(
      spacing: Medidas.s16,
      runSpacing: separacionVertical,
      crossAxisAlignment: alineacion,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: p.textSecondary,
            ),
            const SizedBox(width: Medidas.s8),
            Flexible(
              child: Text(
                fecha,
                style: Textos.leyenda.copyWith(color: p.textSecondary),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: p.accentInk),
            const SizedBox(width: Medidas.s8),
            Flexible(
              child: Text(
                horario,
                style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
