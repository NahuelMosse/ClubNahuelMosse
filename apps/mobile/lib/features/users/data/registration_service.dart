import '../../../api/api_client.dart';
import '../domain/registration_data.dart';

/// El pedido de registro a la API (`POST /registro`).
class RegistrationService {
  const RegistrationService(this._api);

  final ApiClient _api;

  /// Lanza [NoConnection] o [ServerError] si el pedido no llega a tener respuesta.
  Future<ApiResponse> register(RegistrationData data) =>
      _api.post('/register', data.toJson());
}
