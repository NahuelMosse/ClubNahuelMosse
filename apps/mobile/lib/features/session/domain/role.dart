/// El rol de una cuenta: lo que decide a qué pantallas entra.
enum Role {
  user('usuario'),
  admin('admin');

  const Role(this.apiValue);

  /// Cómo lo nombra la API.
  final String apiValue;

  static Role? fromApi(String value) =>
      values.where((r) => r.apiValue == value).firstOrNull;
}
