// kit-shape: a screen or error family kept with its private parts.
/// The API rejected the venue: each field with its message.
class VenueRejected implements Exception {
  const VenueRejected(this.errors, {this.duplicate = false});
  final Map<String, String> errors;

  /// Another active venue already has that name (409), it is not a format problem.
  final bool duplicate;
}

/// The venue is no longer active: another session deactivated it.
class VenueUnavailable implements Exception {
  const VenueUnavailable();
}

/// The venue has active bookings that have not ended yet: it is not deactivated.
class VenueHasBookings implements Exception {
  const VenueHasBookings();
}

/// The new schedule leaves [count] future bookings outside: it has to be confirmed.
class BookingsOutsideHours implements Exception {
  const BookingsOutsideHours(this.count);
  final int count;
}
