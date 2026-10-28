/// La API rechazó la sede: cada campo con su mensaje.
class VenueRejected implements Exception {
  const VenueRejected(this.errors, {this.duplicate = false});
  final Map<String, String> errors;

  /// Otra sede activa ya tiene ese nombre (409), no es un problema de formato.
  final bool duplicate;
}

/// La sede ya no está activa: la dio de baja otra sesión.
class VenueUnavailable implements Exception {
  const VenueUnavailable();
}

/// La sede tiene reservas activas que todavía no terminaron: no se da de baja.
class VenueHasBookings implements Exception {
  const VenueHasBookings();
}

/// El horario nuevo deja afuera [count] reservas futuras: hay que confirmarlo.
class BookingsOutsideHours implements Exception {
  const BookingsOutsideHours(this.count);
  final int count;
}
