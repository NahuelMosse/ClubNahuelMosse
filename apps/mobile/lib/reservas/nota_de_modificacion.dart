import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import 'nota_de_horarios.dart';
import 'reservas.dart';

/// El aviso de que se está modificando [reserva], con la duración que se mantiene.
class NotaDeModificacion extends StatelessWidget {
  const NotaDeModificacion({
    super.key,
    required this.reserva,
    required this.horas,
  });

  final Reserva reserva;
  final int horas;

  @override
  Widget build(BuildContext context) {
    return NotaDeHorarios(
      texto:
          'Estás modificando tu reserva del '
          '${diaCorto(reserva.inicio)}, '
          '${rangoDeHoras(reserva.inicio, reserva.fin)}. '
          'Mantenés la misma duración de ${duracion(horas)} '
          'y el horario anterior se libera al guardar.',
    );
  }
}
