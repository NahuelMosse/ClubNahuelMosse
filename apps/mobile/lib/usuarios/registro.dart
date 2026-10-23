import '../api/cliente_api.dart';
import '../comun/reglas_registro.dart';

/// Lo que la persona completó en el formulario de registro.
class DatosDeRegistro {
  const DatosDeRegistro({
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.fechaNacimiento,
    required this.correo,
    required this.contrasena,
  });

  final String nombre;
  final String apellido;
  final String dni;
  final DateTime fechaNacimiento;
  final String correo;
  final String contrasena;

  /// Los campos con el nombre que usa la API.
  Map<String, Object?> aJson() => {
    'nombre': nombre,
    'apellido': apellido,
    'dni': dni,
    'fecha_nacimiento': fechaIso(fechaNacimiento),
    'correo': correo,
    'contrasena': contrasena,
  };
}

/// El pedido de registro a la API (`POST /registro`).
class RegistroServicio {
  const RegistroServicio(this._api);

  final ClienteApi _api;

  /// Lanza [SinConexion] o [ErrorDelServidor] si el pedido no llega a tener respuesta.
  Future<Respuesta> registrar(DatosDeRegistro datos) =>
      _api.post('/registro', datos.aJson());
}
