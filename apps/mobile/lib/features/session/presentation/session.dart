import 'package:flutter/foundation.dart';

import '../../../common/network_failure.dart';
import '../data/session_repository.dart';
import '../domain/profile.dart';
import '../domain/session_exceptions.dart';
import '../domain/token_source.dart';

/// La sesión de la app: inicia, retoma la que quedó guardada y la cierra.
class Session extends ChangeNotifier implements TokenSource {
  Session({required SessionRepository repository}) : _repository = repository;

  final SessionRepository _repository;

  /// Lo que hay que empezar con la sesión todavía abierta al cerrarla, como avisarle a la API
  /// que este teléfono deja de recibir avisos: recibe el token de la sesión que se cierra. Si
  /// algo falla, la sesión se cierra igual.
  final onClose = <Future<void> Function(String)>[];

  /// Lo que hay que hacer cada vez que el teléfono sale de una sesión, sea cual sea el camino:
  /// cerrarla, una cuenta que ya no vale o una baja. Si algo falla, se sigue igual.
  final onExit = <Future<void> Function()>[];

  Profile? _profile;

  Profile? get profile => _profile;

  set _current(Profile? profile) {
    _profile = profile;
    notifyListeners();
  }

  /// Lanza [InvalidCredentials], [SinConexion] o [ErrorDelServidor]. Si falla después
  /// de que Firebase aceptó la contraseña, no deja una sesión a medias.
  Future<Profile> signIn(String email, String password) async {
    await _repository.credentials.signIn(email.trim().toLowerCase(), password);
    try {
      final profile = await _repository.fetchProfile();
      _current = profile;
      return profile;
    } on Object {
      await _leave();
      rethrow;
    }
  }

  /// La sesión que quedó abierta en el dispositivo, si todavía vale.
  ///
  /// Sólo la cierra si la cuenta ya no es válida. Sin red o con la API caída conserva la
  /// sesión y lanza [SinConexion] o [ErrorDelServidor] para que el arranque ofrezca reintentar.
  Future<Profile?> resume() async {
    if (!_repository.hasAccount) return null;
    try {
      final profile = await _repository.fetchProfile();
      _current = profile;
      return profile;
    } on InvalidCredentials {
      await _leave();
      return null;
    }
  }

  /// Vuelve a pedir el perfil a la API: los datos no se guardan en el dispositivo.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<Profile> refresh() async {
    final before = _profile;
    final Profile profile;
    try {
      profile = await _repository.fetchProfile();
    } on InvalidCredentials {
      throw const SessionExpired();
    }
    _ifStillSame(before, profile);
    return profile;
  }

  /// Guarda [profile] sólo si la sesión es la misma que cuando salió el pedido: si mientras
  /// tanto se cerró o entró otra cuenta, la respuesta ya no le corresponde.
  void _ifStillSame(Profile? before, Profile profile) {
    if (!identical(_profile, before)) throw const SessionExpired();
    _current = profile;
  }

  /// Guarda los datos personales y devuelve el perfil que quedó en la API.
  ///
  /// Lanza [DataRejected], [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<Profile> updateProfile({
    required String firstName,
    required String lastName,
    required String dni,
    required String birthDate,
  }) async {
    final token = await this.token();
    final before = _profile;
    final profile = await _repository.updateProfile(
      token,
      firstName: firstName,
      lastName: lastName,
      dni: dni,
      birthDate: birthDate,
    );
    _ifStillSame(before, profile);
    return profile;
  }

  /// Lanza [PasswordRejected], [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<void> changePassword(String current, String newPassword) async {
    final profile = _profile;
    final token = await this.token();
    if (profile == null) throw const SessionExpired();
    await _repository.changePassword(
      token,
      profile.email,
      current,
      newPassword,
    );
  }

  /// Da de baja la cuenta y cierra la sesión del dispositivo.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor]; en esos casos la cuenta
  /// sigue igual.
  Future<void> deactivate() async {
    final token = await this.token();
    final before = _profile;
    await _repository.deactivate(token);
    // Si mientras tanto se cerró la sesión o entró otra cuenta, no se la toca.
    if (!identical(_profile, before)) return;
    try {
      await _leave();
    } on Exception {
      // La cuenta ya no existe en la API: el próximo arranque encuentra vencida la sesión
      // de Firebase que haya quedado y la cierra.
    }
    _current = null;
  }

  /// El ID token de quien tiene la sesión, para los pedidos de otras pantallas.
  ///
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  @override
  Future<String> token() => _repository.token();

  /// Si Firebase no puede borrar la sesión del dispositivo, lanza y la sesión sigue abierta.
  Future<void> close() async {
    final deactivations = <Future<void>>[];
    if (onClose.isNotEmpty) {
      String? token;
      try {
        token = await _repository.currentToken().timeout(
          const Duration(seconds: 2),
        );
      } on Exception {
        // Sin token no hay nada que avisarle a la API: la sesión se cierra igual.
      }
      if (token != null) {
        // El error se engancha al crear cada pedido: si falla antes de que termine de cerrarse
        // la sesión, no queda un error sin atrapar.
        for (final f in onClose) {
          deactivations.add(
            f(token)
                .timeout(const Duration(seconds: 3))
                .then((_) {}, onError: (Object _) {}),
          );
        }
      }
    }
    await _repository.credentials.signOut();
    _current = null;
    // La pantalla ya muestra el login: lo que queda se hace sin hacer esperar a la persona.
    await _notifyExit();
    await Future.wait(deactivations);
  }

  /// Borra la sesión de Firebase del dispositivo y le avisa a quien lo necesite que el teléfono
  /// ya no es de esa cuenta. Lo que falle después de salir no cambia que se salió.
  Future<void> _leave() async {
    await _repository.credentials.signOut();
    await _notifyExit();
  }

  Future<void> _notifyExit() async {
    for (final f in [...onExit]) {
      try {
        await f().timeout(const Duration(seconds: 3));
      } on Exception {
        // Sin red o con el servicio caído, la persona igual salió.
      }
    }
  }
}
