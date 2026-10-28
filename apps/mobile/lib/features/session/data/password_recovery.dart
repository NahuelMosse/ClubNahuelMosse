import '../../../api/cliente_api.dart';
import '../../../common/field_errors.dart';
import '../domain/recovery_exceptions.dart';
import '../domain/session_exceptions.dart';

/// Recuperar la contraseña sin sesión: pedir el enlace y crear la nueva con él.
class PasswordRecovery {
  const PasswordRecovery(this._api);

  final ClienteApi _api;

  /// Lanza [EmailRejected], [SinConexion] o [ErrorDelServidor]. La respuesta es la misma
  /// tenga o no cuenta el correo.
  Future<void> requestLink(String email) async {
    final r = await _api.post('/recuperacion', {'correo': email});
    if (r.codigo == 202) return;
    if (r.codigo == 422) {
      if (fieldErrors(r.cuerpo)['correo'] case final message?) {
        throw EmailRejected(message);
      }
    }
    throw ErrorDelServidor(r.codigo);
  }

  /// Si el enlace todavía sirve. Lanza [SinConexion] o [ErrorDelServidor].
  Future<bool> isValid(String code) async {
    if (code.isEmpty) return false;
    final r = await _api.post('/recuperacion/consulta', {'codigo': code});
    return switch (r.codigo) {
      204 => true,
      410 => false,
      _ => throw ErrorDelServidor(r.codigo),
    };
  }

  /// Lanza [InvalidLink], [PasswordRejected], [SinConexion] o [ErrorDelServidor].
  Future<void> createPassword(String code, String newPassword) async {
    final r = await _api.put('/recuperacion', {
      'codigo': code,
      'nueva': newPassword,
    });
    switch (r.codigo) {
      case 204:
        return;
      case 410:
        throw const InvalidLink();
      case 422:
        if (fieldErrors(r.cuerpo)['nueva'] case final message?) {
          throw PasswordRejected({'nueva': message});
        }
    }
    throw ErrorDelServidor(r.codigo);
  }
}
