/// Quien entrega el ID token de la sesión abierta, para los pedidos que lo necesitan.
abstract interface class TokenSource {
  /// Lanza [SessionExpired], [SinConexion] o [ErrorDelServidor].
  Future<String> token();
}
