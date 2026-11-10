import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../domain/recovery_exceptions.dart';
import '../domain/session_exceptions.dart';

/// Recuperar la contraseña sin sesión: pedir el enlace y crear la nueva con él.
class PasswordRecovery {
  const PasswordRecovery(this._api);

  final ApiClient _api;

  /// Lanza [EmailRejected], [NoConnection] o [ServerError]. La respuesta es la misma
  /// tenga o no cuenta el correo.
  Future<void> requestLink(String email) async {
    final r = await _api.post('/password-recovery', {'email': email});
    if (r.code == 202) return;
    if (r.code == 422) {
      if (fieldErrors(r.body)['email'] case final message?) {
        throw EmailRejected(message);
      }
    }
    throw ServerError(r.code);
  }

  /// Si el enlace todavía sirve. Lanza [NoConnection] o [ServerError].
  Future<bool> isValid(String code) async {
    if (code.isEmpty) return false;
    final r = await _api.post('/password-recovery/check', {'code': code});
    return switch (r.code) {
      204 => true,
      410 => false,
      _ => throw ServerError(r.code),
    };
  }

  /// Lanza [InvalidLink], [PasswordRejected], [NoConnection] o [ServerError].
  Future<void> createPassword(String code, String newPassword) async {
    final r = await _api.put('/password-recovery', {
      'code': code,
      'new_password': newPassword,
    });
    switch (r.code) {
      case 204:
        return;
      case 410:
        throw const InvalidLink();
      case 422:
        if (fieldErrors(r.body)['new_password'] case final message?) {
          throw PasswordRejected({'new_password': message});
        }
    }
    throw ServerError(r.code);
  }
}
