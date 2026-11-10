/// Quien entrega el ID token de la sesión abierta, para los pedidos que lo necesitan.
abstract interface class TokenSource {
  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<String> token();
}
