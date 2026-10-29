/// El rol de una cuenta: lo que decide a qué pantallas entra.
enum Role {
  user('user', 'usuario'),
  admin('admin', 'admin');

  const Role(this.apiValue, this.label);

  /// Cómo lo nombra la API.
  final String apiValue;

  /// Cómo se lo nombra a la persona.
  final String label;

  static Role? fromApi(String value) =>
      values.where((r) => r.apiValue == value).firstOrNull;
}
