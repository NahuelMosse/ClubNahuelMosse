import '../api/cliente_api.dart';
import 'sesion.dart';

/// El enlace del correo venció, ya se usó o quedó reemplazado por uno más nuevo.
class EnlaceInvalido implements Exception {
  const EnlaceInvalido();
}

/// El formato del correo que la API rechazó, con su mensaje.
class CorreoRechazado implements Exception {
  const CorreoRechazado(this.mensaje);
  final String mensaje;
}

/// Recuperar la contraseña sin sesión: pedir el enlace y crear la nueva con él.
class Recuperacion {
  const Recuperacion(this._api);

  final ClienteApi _api;

  /// Lanza [CorreoRechazado], [SinConexion] o [ErrorDelServidor]. La respuesta es la misma
  /// tenga o no cuenta el correo.
  Future<void> pedirEnlace(String correo) async {
    final r = await _api.post('/recuperacion', {'correo': correo});
    if (r.codigo == 202) return;
    if (r.codigo == 422) {
      if (r.cuerpo['errores'] case {'correo': final String mensaje}) {
        throw CorreoRechazado(mensaje);
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Si el enlace todavía sirve. Lanza [SinConexion] o [ErrorDelServidor].
  Future<bool> vigente(String codigo) async {
    if (codigo.isEmpty) return false;
    final r = await _api.post('/recuperacion/consulta', {'codigo': codigo});
    return switch (r.codigo) {
      204 => true,
      410 => false,
      _ => throw ErrorDelServidor(r.codigo),
    };
  }

  /// Lanza [EnlaceInvalido], [ContrasenaRechazada], [SinConexion] o [ErrorDelServidor].
  Future<void> crearContrasena(String codigo, String nueva) async {
    final r = await _api.put('/recuperacion', {
      'codigo': codigo,
      'nueva': nueva,
    });
    switch (r.codigo) {
      case 204:
        return;
      case 410:
        throw const EnlaceInvalido();
      case 422:
        if (r.cuerpo['errores'] case {'nueva': final String mensaje}) {
          throw ContrasenaRechazada({'nueva': mensaje});
        }
    }
    throw ErrorDelServidor(r.codigo);
  }
}
