/// The space or its venue can no longer be booked.
class SpaceUnavailable implements Exception {
  const SpaceUnavailable();
}

/// The requested day is no longer among those that can be queried: midnight passed.
class DateExpired implements Exception {
  const DateExpired();
}

/// The API rejected the queried range: each field with its message.
class RangeRejected implements Exception {
  const RangeRejected(this.errors);
  final Map<String, String> errors;
}
