import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    return AvailabilityNote(
      texto: l.bookingModifyNote(
        shortDay(reserva.startsAt),
        l.bookingDuration(horas),
        timeRange(reserva.startsAt, reserva.endsAt),
      ),
    );
  }
}
