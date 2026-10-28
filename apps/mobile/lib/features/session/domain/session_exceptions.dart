// kit-shape: a screen or error family kept with its private parts.
/// Correo o contraseña que no corresponden a una cuenta activa. No dice cuál de los dos.
class InvalidCredentials implements Exception {
  const InvalidCredentials();
}

/// La API ya no reconoce la sesión: venció o se cerró desde otro dispositivo.
class SessionExpired implements Exception {
  const SessionExpired();
}

/// La API rechazó los datos personales: cada campo con su mensaje.
class DataRejected implements Exception {
  const DataRejected(this.errors, {this.duplicate = false});
  final Map<String, String> errors;

  /// Otra cuenta ya tiene ese dato (409), no es un problema de formato.
  final bool duplicate;
}

/// La API rechazó el cambio: cada campo con su mensaje.
class PasswordRejected implements Exception {
  const PasswordRejected(this.errors);
  final Map<String, String> errors;
}
