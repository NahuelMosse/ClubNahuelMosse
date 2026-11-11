// kit-shape: a screen or error family kept with its private parts.
/// The space or its venue are no longer active: another session deactivated them.
class SpaceUnavailable implements Exception {
  const SpaceUnavailable();
}

/// The space has active bookings that have not ended yet: it is not deactivated.
class SpaceHasBookings implements Exception {
  const SpaceHasBookings();
}

/// The API rejected the space: each field with its message.
class SpaceRejected implements Exception {
  const SpaceRejected(this.errors);
  final Map<String, String> errors;
}

/// The number that was shown was already taken by another creation; [name] and [number]
/// are the next ones.
class NameTaken implements Exception {
  const NameTaken(this.message, this.name, this.number);
  final String message;
  final String name;
  final int number;
}
