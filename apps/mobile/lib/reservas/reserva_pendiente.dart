import 'eleccion.dart';

/// La reserva que se estaba por confirmar cuando la sesión venció: al volver a entrar con
/// la misma cuenta, la app lleva de nuevo a la confirmación. Vive mientras la app está
/// abierta.
class ReservaPendiente {
  Eleccion? _eleccion;
  String? _correo;

  void guardar(Eleccion eleccion, String correo) {
    _eleccion = eleccion;
    _correo = correo.trim().toLowerCase();
  }

  /// Si hay una pendiente de la cuenta [correo]; si es de otra, se descarta.
  bool esDe(String correo) {
    if (_eleccion == null) return false;
    if (_correo == correo.trim().toLowerCase()) return true;
    _eleccion = null;
    _correo = null;
    return false;
  }

  /// La elección pendiente, que deja de estarlo.
  Eleccion? tomar() {
    final eleccion = _eleccion;
    _eleccion = null;
    _correo = null;
    return eleccion;
  }
}
