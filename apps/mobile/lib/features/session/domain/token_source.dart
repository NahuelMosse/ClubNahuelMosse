/// Whoever delivers the ID token of the open session, for the requests that need it.
abstract interface class TokenSource {
  /// Lanza [SessionExpired], [NoConnection] o [ServerError].
  Future<String> token();
}
