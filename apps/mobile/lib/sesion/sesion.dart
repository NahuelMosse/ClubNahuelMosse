import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../api/cliente_api.dart';

enum Rol { usuario, admin }

class Perfil {
  const Perfil({
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.rol,
    required this.dni,
    required this.fechaNacimiento,
  });

  final String nombre;
  final String apellido;
  final String correo;
  final Rol rol;
  final String dni;
  final DateTime fechaNacimiento;

  /// La ruta a la que entra cada rol después de iniciar sesión.
  String get inicio => rol == Rol.admin ? '/admin' : '/inicio';
}

/// Correo o contraseña que no corresponden a una cuenta activa. No dice cuál de los dos.
class CredencialesInvalidas implements Exception {
  const CredencialesInvalidas();
}

/// La API ya no reconoce la sesión: venció o se cerró desde otro dispositivo.
class SesionVencida implements Exception {
  const SesionVencida();
}

/// La API rechazó los datos personales: cada campo con su mensaje.
class DatosRechazados implements Exception {
  const DatosRechazados(this.errores, {this.repetido = false});
  final Map<String, String> errores;

  /// Otra cuenta ya tiene ese dato (409), no es un problema de formato.
  final bool repetido;
}

/// La API rechazó el cambio: cada campo con su mensaje.
class ContrasenaRechazada implements Exception {
  const ContrasenaRechazada(this.errores);
  final Map<String, String> errores;
}

/// Quién comprueba el correo y la contraseña, y guarda la sesión en el dispositivo.
abstract interface class Credenciales {
  bool get hayCuenta;

  /// Lanza [CredencialesInvalidas], [SinConexion] o [ErrorDelServidor].
  Future<void> ingresar(String correo, String contrasena);

  Future<String?> token();

  Future<void> salir();
}

class CredencialesFirebase implements Credenciales {
  CredencialesFirebase(this._auth);

  final FirebaseAuth _auth;

  // Firebase no distingue correo inexistente de contraseña incorrecta
  // (`invalid-credential`) cuando la protección contra enumeración está activa.
  static const _rechazos = {
    'invalid-credential',
    'invalid-email',
    'user-not-found',
    'wrong-password',
    'user-disabled',
    'missing-password',
    'too-many-requests',
  };

  @override
  bool get hayCuenta => _auth.currentUser != null;

  @override
  Future<void> ingresar(String correo, String contrasena) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw const SinConexion();
      if (_rechazos.contains(e.code)) throw const CredencialesInvalidas();
      throw const ErrorDelServidor(0);
    }
  }

  // La cuenta ya no vale: no hay token que refrescar.
  static const _cuentaCaida = {
    'user-token-expired',
    'user-disabled',
    'user-not-found',
    'invalid-user-token',
  };

  @override
  Future<String?> token() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') throw const SinConexion();
      if (_cuentaCaida.contains(e.code)) throw const CredencialesInvalidas();
      throw const ErrorDelServidor(0);
    }
  }

  @override
  Future<void> salir() => _auth.signOut();
}

/// La sesión de la app: inicia, retoma la que quedó guardada y la cierra.
class Sesion extends ChangeNotifier {
  Sesion({
    required Credenciales credenciales,
    required ClienteApi api,
    this.limiteAlRetomar = const Duration(seconds: 3),
  }) : _credenciales = credenciales,
       _api = api;

  final Credenciales _credenciales;
  final ClienteApi _api;

  /// Cuánto puede esperar el arranque a la API antes de mostrar el login.
  final Duration limiteAlRetomar;
  Perfil? _perfil;

  Perfil? get perfil => _perfil;

  set _actual(Perfil? perfil) {
    _perfil = perfil;
    notifyListeners();
  }

  /// Lanza [CredencialesInvalidas], [SinConexion] o [ErrorDelServidor]. Si falla después
  /// de que Firebase aceptó la contraseña, no deja una sesión a medias.
  Future<Perfil> iniciar(String correo, String contrasena) async {
    await _credenciales.ingresar(correo.trim().toLowerCase(), contrasena);
    try {
      final perfil = await _perfilPropio();
      _actual = perfil;
      return perfil;
    } on Object {
      await _credenciales.salir();
      rethrow;
    }
  }

  /// La sesión que quedó abierta en el dispositivo, si todavía vale.
  ///
  /// Sólo la cierra si la cuenta ya no es válida. Sin red, con la API caída o lenta, la
  /// conserva para el próximo arranque y deja entrar por el login.
  Future<Perfil?> retomar() async {
    if (!_credenciales.hayCuenta) return null;
    try {
      final perfil = await _perfilPropio().timeout(limiteAlRetomar);
      _actual = perfil;
      return perfil;
    } on CredencialesInvalidas {
      await _credenciales.salir();
      return null;
    } on Exception {
      return null;
    }
  }

  /// Vuelve a pedir el perfil a la API: los datos no se guardan en el dispositivo.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<Perfil> refrescar() async {
    final antes = _perfil;
    final Perfil perfil;
    try {
      perfil = await _perfilPropio();
    } on CredencialesInvalidas {
      throw const SesionVencida();
    }
    _siSigueLaMisma(antes, perfil);
    return perfil;
  }

  /// Guarda [perfil] sólo si la sesión es la misma que cuando salió el pedido: si mientras
  /// tanto se cerró o entró otra cuenta, la respuesta ya no le corresponde.
  void _siSigueLaMisma(Perfil? antes, Perfil perfil) {
    if (!identical(_perfil, antes)) throw const SesionVencida();
    _actual = perfil;
  }

  /// Guarda los datos personales y devuelve el perfil que quedó en la API. El correo no
  /// se manda: no se puede cambiar.
  ///
  /// Lanza [DatosRechazados], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<Perfil> editarPerfil({
    required String nombre,
    required String apellido,
    required String dni,
    required String fechaNacimiento,
  }) async {
    final String? token;
    try {
      token = await _credenciales.token();
    } on CredencialesInvalidas {
      throw const SesionVencida();
    }
    if (token == null) throw const SesionVencida();
    final antes = _perfil;
    final r = await _api.put('/yo', {
      'nombre': nombre,
      'apellido': apellido,
      'dni': dni,
      'fecha_nacimiento': fechaNacimiento,
    }, token: token);
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo == 409 || r.codigo == 422) {
      final errores = switch (r.cuerpo['errores']) {
        final Map<String, Object?> mapa => {
          for (final MapEntry(:key, :value) in mapa.entries)
            if (value is String) key: value,
        },
        _ => const <String, String>{},
      };
      if (errores.isNotEmpty) {
        throw DatosRechazados(errores, repetido: r.codigo == 409);
      }
    }
    final perfil = _perfilDe(r);
    _siSigueLaMisma(antes, perfil);
    return perfil;
  }

  /// Cambia la contraseña de quien tiene la sesión y vuelve a entrar con la nueva, porque
  /// la API invalida todas las sesiones abiertas de la cuenta, esta incluida.
  ///
  /// Lanza [ContrasenaRechazada], [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<void> cambiarContrasena(String actual, String nueva) async {
    final perfil = _perfil;
    final String? token;
    try {
      token = await _credenciales.token();
    } on CredencialesInvalidas {
      // Firebase ya no refresca la sesión: la cuenta cambió en otro lado.
      throw const SesionVencida();
    }
    if (perfil == null || token == null) throw const SesionVencida();
    final r = await _api.put('/yo/contrasena', {
      'actual': actual,
      'nueva': nueva,
    }, token: token);
    switch (r.codigo) {
      case 204:
        try {
          await _credenciales.ingresar(perfil.correo, nueva);
        } on Exception {
          // La contraseña ya cambió. Si no se pudo volver a entrar, el próximo pedido a la
          // API avisa que la sesión venció.
        }
      case 401:
        throw const SesionVencida();
      case 422:
        final errores = switch (r.cuerpo['errores']) {
          final Map<String, Object?> mapa => {
            for (final MapEntry(:key, :value) in mapa.entries)
              if (value is String) key: value,
          },
          _ => const <String, String>{},
        };
        if (errores.isEmpty) throw ErrorDelServidor(r.codigo);
        throw ContrasenaRechazada(errores);
      default:
        // 429: Firebase frena por demasiados intentos con la contraseña actual.
        throw ErrorDelServidor(r.codigo);
    }
  }

  /// Da de baja la cuenta y cierra la sesión del dispositivo.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor]; en esos casos la cuenta
  /// sigue igual.
  Future<void> darDeBaja() async {
    final String? token;
    try {
      token = await _credenciales.token();
    } on CredencialesInvalidas {
      throw const SesionVencida();
    }
    if (token == null) throw const SesionVencida();
    final antes = _perfil;
    final r = await _api.delete('/yo', token: token);
    if (r.codigo == 401) throw const SesionVencida();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
    // Si mientras tanto se cerró la sesión o entró otra cuenta, no se la toca.
    if (!identical(_perfil, antes)) return;
    try {
      await _credenciales.salir();
    } on Exception {
      // La cuenta ya no existe en la API: aunque quede la sesión de Firebase guardada, el
      // próximo arranque la encuentra vencida y la cierra.
    }
    _actual = null;
  }

  /// El ID token de quien tiene la sesión, para los pedidos de otras pantallas.
  ///
  /// Lanza [SesionVencida], [SinConexion] o [ErrorDelServidor].
  Future<String> token() async {
    final String? token;
    try {
      token = await _credenciales.token();
    } on CredencialesInvalidas {
      throw const SesionVencida();
    }
    if (token == null) throw const SesionVencida();
    return token;
  }

  /// Si Firebase no puede borrar la sesión del dispositivo, lanza y la sesión sigue abierta.
  Future<void> cerrar() async {
    await _credenciales.salir();
    _actual = null;
  }

  Future<Perfil> _perfilPropio() async {
    final token = await _credenciales.token();
    if (token == null) throw const CredencialesInvalidas();
    return _perfilDe(await _api.get('/yo', token: token));
  }

  Perfil _perfilDe(Respuesta r) {
    if (r.codigo == 401) throw const CredencialesInvalidas();
    if (r.codigo != 200) throw ErrorDelServidor(r.codigo);
    if (r.cuerpo case {
      'nombre': final String nombre,
      'apellido': final String apellido,
      'correo': final String correo,
      'rol': final String rol,
      'dni': final String dni,
      'fecha_nacimiento': final String nacimiento,
    }) {
      final conocido = Rol.values.asNameMap()[rol];
      final fecha = DateTime.tryParse(nacimiento);
      if (conocido != null && fecha != null) {
        return Perfil(
          nombre: nombre,
          apellido: apellido,
          correo: correo,
          rol: conocido,
          dni: dni,
          fechaNacimiento: fecha,
        );
      }
    }
    throw ErrorDelServidor(r.codigo);
  }
}
