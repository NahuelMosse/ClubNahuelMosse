import '../../../l10n/app_localizations.dart';
import '../domain/booking_status.dart';

/// «Activa», «Completada», «Cancelada» or «Anulada», in the language of [l].
String bookingStatusText(AppLocalizations l, BookingStatus status) =>
    switch (status) {
      BookingStatus.active => l.bookingStatusActive,
      BookingStatus.completed => l.bookingStatusCompleted,
      BookingStatus.canceled => l.bookingStatusCanceled,
      BookingStatus.voided => l.bookingStatusVoided,
    };
