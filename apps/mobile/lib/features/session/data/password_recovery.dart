import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../domain/recovery_exceptions.dart';
import '../domain/session_exceptions.dart';

/// Recovering the password without a session: asking for the link and creating the new
/// one with it.
class PasswordRecovery {
  const PasswordRecovery(this._api);

  final ApiClient _api;

  /// Throws [EmailRejected], [NoConnection] or [ServerError]. The answer is the same
  /// whether or not the email has an account.
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

  /// Whether the link still works. Throws [NoConnection] or [ServerError].
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
