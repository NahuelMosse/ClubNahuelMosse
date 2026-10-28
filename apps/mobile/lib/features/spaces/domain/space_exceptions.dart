/// El espacio o su sede ya no están activos: los dio de baja otra sesión.
class SpaceUnavailable implements Exception {
  const SpaceUnavailable();
}

/// El espacio tiene reservas activas que todavía no terminaron: no se da de baja.
class SpaceHasBookings implements Exception {
  const SpaceHasBookings();
}

/// La API rechazó el espacio: cada campo con su mensaje.
class SpaceRejected implements Exception {
  const SpaceRejected(this.errors);
  final Map<String, String> errors;
}

/// El número que se mostraba ya lo tomó otro alta; [name] y [number] son los siguientes.
class NameTaken implements Exception {
  const NameTaken(this.message, this.name, this.number);
  final String message;
  final String name;
  final int number;
}
