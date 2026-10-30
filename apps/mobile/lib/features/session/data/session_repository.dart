import '../../../api/api_client.dart';
import '../../../common/field_errors.dart';
import '../domain/profile.dart';
import '../domain/role.dart';
import '../domain/session_exceptions.dart';
import '../domain/token_source.dart';
import 'credentials.dart';

/// Los pedidos de la sesión a la API y a Firebase. Los que necesitan el token lo reciben
/// ya resuelto: quién lo pide decide el orden.
class SessionRepository implements TokenSource {
  SessionRepository({required this.credentials, required ApiClient api})
    : _api = api;

  /// Entrar y salir de la cuenta de Firebase: quien lo necesita llama directo.
  final Credentials credentials;
  final ApiClient _api;

  bool get hasAccount => credentials.hasAccount;

  /// El token tal como lo entrega Firebase, sin traducir; `null` si no hay cuenta.
  Future<String?> currentToken() => credentials.token();

  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
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

  /// Lanza [InvalidCredentials], [SinConexion] o [ErrorDelServidor].
  Future<Profile> fetchProfile() async {
    final token = await credentials.token();
    if (token == null) throw const InvalidCredentials();
    return _profileFrom(await _api.get('/me', token: token));
  }

  /// Lanza [DataRejected], [SessionExpired], [SinConexion] o [ErrorDelServidor].
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
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo == 409 || r.codigo == 422) {
      final errors = fieldErrors(r.cuerpo);
      if (errors.isNotEmpty) {
        throw DataRejected(errors, duplicate: r.codigo == 409);
      }
    }
    return _profileFrom(r);
  }

  /// Cambia la contraseña y vuelve a entrar con la nueva: la API invalida todas las
  /// sesiones abiertas de la cuenta, esta incluida.
  ///
  /// Lanza [PasswordRejected], [SessionExpired], [SinConexion] o [ErrorDelServidor].
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
    switch (r.codigo) {
      case 204:
        try {
          await credentials.signIn(email, newPassword);
        } on Exception {
          // La contraseña ya cambió. Si no se pudo volver a entrar, el próximo pedido a la
          // API avisa que la sesión venció.
        }
      case 401:
        throw const SessionExpired();
      case 422:
        final errors = fieldErrors(r.cuerpo);
        if (errors.isEmpty) throw ErrorDelServidor(r.codigo);
        throw PasswordRejected(errors);
      default:
        // 429: Firebase frena por demasiados intentos con la contraseña actual.
        throw ErrorDelServidor(r.codigo);
    }
  }

  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<void> deactivate(String token) async {
    final r = await _api.delete('/me', token: token);
    if (r.codigo == 401) throw const SessionExpired();
    if (r.codigo != 204) throw ErrorDelServidor(r.codigo);
  }

  Profile _profileFrom(Respuesta r) {
    if (r.codigo == 401) throw const InvalidCredentials();
    if (r.codigo != 200) throw ErrorDelServidor(r.codigo);
    if (r.cuerpo case {
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
    throw ErrorDelServidor(r.codigo);
  }
}
