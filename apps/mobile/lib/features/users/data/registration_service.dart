import '../../../api/api_client.dart';
import '../domain/registration_data.dart';

/// The registration request to the API (`POST /registro`).
class RegistrationService {
  const RegistrationService(this._api);

  final ApiClient _api;

  /// Throws [NoConnection] or [ServerError] if the request never gets a response.
  Future<ApiResponse> register(RegistrationData data) =>
      _api.post('/register', data.toJson());
}
