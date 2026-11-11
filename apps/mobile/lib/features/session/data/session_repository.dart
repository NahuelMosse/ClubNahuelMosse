import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../domain/profile.dart';
import '../domain/role.dart';
import '../domain/session_exceptions.dart';
import '../domain/token_source.dart';
import 'credentials.dart';

/// The session's requests to the API and to Firebase. The ones that need the token
/// receive it already resolved: whoever asks decides the order.
class SessionRepository implements TokenSource {
  SessionRepository({required this.credentials, required ApiClient api})
    : _api = api;

  /// Signing in and out of the Firebase account: whoever needs it calls directly.
  final Credentials credentials;
  final ApiClient _api;

  bool get hasAccount => credentials.hasAccount;

  /// The token as Firebase delivers it, untranslated; `null` if there is no account.
  Future<String?> currentToken() => credentials.token();

  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  @override
  Future<String> token() async {
    final String? token;
    try {
      token = await credentials.token();
    } on InvalidCredentials {
      throw const SessionExpired();
    }
    if (token == null) throw const SessionExpired();
    return token;
  }

  /// Lanza [InvalidCredentials], [NoConnection] o [ServerError].
  Future<Profile> fetchProfile() async {
    final token = await credentials.token();
    if (token == null) throw const InvalidCredentials();
    return _profileFrom(await _api.get('/me', token: token));
  }

  /// Lanza [DataRejected], [SessionExpired], [NoConnection] o [ServerError].
  Future<Profile> updateProfile(
    String token, {
    required String firstName,
    required String lastName,
    required String dni,
    required String birthDate,
  }) async {
    final r = await _api.put('/me', {
      'first_name': firstName,
      'last_name': lastName,
      'dni': dni,
      'birth_date': birthDate,
    }, token: token);
    if (r.code == 401) throw const SessionExpired();
    if (r.code == 409 || r.code == 422) {
      final errors = fieldErrors(r.body);
      if (errors.isNotEmpty) {
        throw DataRejected(errors, duplicate: r.code == 409);
      }
    }
    return _profileFrom(r);
  }

  /// Changes the password and signs in again with the new one: the API invalidates all
  /// the open sessions of the account, this one included.
  ///
  /// Throws [PasswordRejected], [SessionExpired], [NoConnection] or [ServerError].
  Future<void> changePassword(
    String token,
    String email,
    String current,
    String newPassword,
  ) async {
    final r = await _api.put('/me/password', {
      'current_password': current,
      'new_password': newPassword,
    }, token: token);
    switch (r.code) {
      case 204:
        try {
          await credentials.signIn(email, newPassword);
        } on Exception {
          // The password already changed. If signing in again was not possible, the next
          // request to the API reports that the session expired.
        }
      case 401:
        throw const SessionExpired();
      case 422:
        final errors = fieldErrors(r.body);
        if (errors.isEmpty) throw ServerError(r.code);
        throw PasswordRejected(errors);
      default:
        // 429: Firebase throttles for too many attempts with the current password.
        throw ServerError(r.code);
    }
  }

  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<void> deactivate(String token) async {
    final r = await _api.delete('/me', token: token);
    if (r.code == 401) throw const SessionExpired();
    if (r.code != 204) throw ServerError(r.code);
  }

  Profile _profileFrom(ApiResponse r) {
    if (r.code == 401) throw const InvalidCredentials();
    if (r.code != 200) throw ServerError(r.code);
    if (r.body case {
      'first_name': final String firstName,
      'last_name': final String lastName,
      'email': final String email,
      'role': final String role,
      'dni': final String dni,
      'birth_date': final String birth,
    }) {
      final known = Role.fromApi(role);
      final date = DateTime.tryParse(birth);
      if (known != null && date != null) {
        return Profile(
          firstName: firstName,
          lastName: lastName,
          email: email,
          role: known,
          dni: dni,
          birthDate: date,
        );
      }
    }
    throw ServerError(r.code);
  }
}
