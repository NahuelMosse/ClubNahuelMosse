// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../l10n/app_localizations.dart';
import '../../bookings/domain/booking_status.dart';

/// The status in the badge of an admin booking, in capitals.
String statusChipText(AppLocalizations l10n, BookingStatus status) =>
    switch (status) {
      BookingStatus.active => l10n.adminStatusActive,
      BookingStatus.completed => l10n.adminStatusCompleted,
      BookingStatus.canceled => l10n.adminStatusCanceled,
      BookingStatus.voided => l10n.adminStatusVoided,
    };

/// The name of a status filter in the panel; `null` is the filter that shows them all.
String statusFilterText(AppLocalizations l10n, BookingStatus? status) =>
    switch (status) {
      null => l10n.adminFilterAll,
      BookingStatus.active => l10n.adminFilterActive,
      BookingStatus.completed => l10n.adminFilterCompleted,
      BookingStatus.canceled => l10n.adminFilterCanceled,
      BookingStatus.voided => l10n.adminFilterVoided,
    };
