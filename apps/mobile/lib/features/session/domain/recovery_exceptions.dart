// kit-shape: a screen or error family kept with its private parts.
/// The link of the email expired, was already used or was replaced by a newer one.
class InvalidLink implements Exception {
  const InvalidLink();
}

/// The format of the email that the API rejected, with its message.
class EmailRejected implements Exception {
  const EmailRejected(this.message);
  final String message;
}
