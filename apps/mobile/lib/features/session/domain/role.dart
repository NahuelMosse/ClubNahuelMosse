/// The role of an account: what decides which screens it can enter.
enum Role {
  user('user'),
  admin('admin');

  const Role(this.apiValue);

  /// How the API names it.
  final String apiValue;

  static Role? fromApi(String value) =>
      values.where((r) => r.apiValue == value).firstOrNull;
}
