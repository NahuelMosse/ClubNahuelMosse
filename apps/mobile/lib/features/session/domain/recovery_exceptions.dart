/// El enlace del correo venció, ya se usó o quedó reemplazado por uno más nuevo.
class InvalidLink implements Exception {
  const InvalidLink();
}

/// El formato del correo que la API rechazó, con su mensaje.
class EmailRejected implements Exception {
  const EmailRejected(this.message);
  final String message;
}
