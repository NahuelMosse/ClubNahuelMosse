// kit-shape: a screen or error family kept with its private parts.
/// Another active booking took that slot first.
class SlotTaken implements Exception {
  const SlotTaken();
}

/// The booking was no longer as it was seen: voided, canceled elsewhere or already
/// started.
class BookingChanged implements Exception {
  const BookingChanged();
}

/// The API rejected the chosen slot: each field with its message.
class BookingRejected implements Exception {
  const BookingRejected(this.errors);
  final Map<String, String> errors;
}
