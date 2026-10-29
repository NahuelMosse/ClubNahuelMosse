/// Los campos del formulario de registro, con el nombre que usa la API.
enum RegistrationField {
  firstName('first_name'),
  lastName('last_name'),
  dni('dni'),
  birthDate('birth_date'),
  email('email'),
  password('password');

  const RegistrationField(this.key);
  final String key;

  static RegistrationField? fromApi(String key) =>
      values.where((c) => c.key == key).firstOrNull;
}
