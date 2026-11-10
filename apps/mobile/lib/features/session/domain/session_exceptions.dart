// kit-shape: a screen or error family kept with its private parts.
/// An email or password that does not match an active account. It does not say which of
/// the two.
class InvalidCredentials implements Exception {
  const InvalidCredentials();
}

/// The API no longer recognizes the session: it expired or was closed from another
/// device.
class SessionExpired implements Exception {
  const SessionExpired();
}

/// The API rejected the personal data: each field with its message.
class DataRejected implements Exception {
  const DataRejected(this.errors, {this.duplicate = false});
  final Map<String, String> errors;

  /// Another account already has that datum (409), it is not a format problem.
  final bool duplicate;
}

/// The API rejected the change: each field with its message.
class PasswordRejected implements Exception {
  const PasswordRejected(this.errors);
  final Map<String, String> errors;
}
