/// Los campos del formulario de registro, con el nombre que usa la API.
enum RegistrationField {
  firstName('nombre'),
  lastName('apellido'),
  dni('dni'),
  birthDate('fecha_nacimiento'),
  email('correo'),
  password('contrasena');

  const RegistrationField(this.key);
  final String key;

  static RegistrationField? fromApi(String key) =>
      values.where((c) => c.key == key).firstOrNull;
}
