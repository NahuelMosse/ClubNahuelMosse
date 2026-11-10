import 'package:flutter/material.dart';

import '../../../common/dates.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/booking.dart';
import 'availability_note.dart';

/// El aviso de que se está modifying [booking], con la duración que se mantiene.
class ModificationNote extends StatelessWidget {
  const ModificationNote({
    super.key,
    required this.booking,
    required this.hours,
  });

  final Booking booking;
  final int hours;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AvailabilityNote(
      text: l.bookingModifyNote(
        shortDay(booking.startsAt),
        l.bookingDuration(hours),
        timeRange(booking.startsAt, booking.endsAt),
      ),
    );
  }
}
