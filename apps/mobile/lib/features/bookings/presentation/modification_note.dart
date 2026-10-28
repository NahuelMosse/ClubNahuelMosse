import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../domain/booking.dart';
import 'availability_note.dart';

/// El aviso de que se está modificando [reserva], con la duración que se mantiene.
class ModificationNote extends StatelessWidget {
  const ModificationNote({
    super.key,
    required this.reserva,
    required this.horas,
  });

  final Booking reserva;
  final int horas;

  @override
  Widget build(BuildContext context) {
    return AvailabilityNote(
      texto:
          'Estás modificando tu reserva del '
          '${shortDay(reserva.startsAt)}, '
          '${timeRange(reserva.startsAt, reserva.endsAt)}. '
          'Mantenés la misma duración de ${duration(horas)} '
          'y el horario anterior se libera al guardar.',
    );
  }
}
