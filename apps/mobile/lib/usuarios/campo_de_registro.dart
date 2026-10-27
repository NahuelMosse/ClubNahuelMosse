/// Los campos del formulario de registro, con el nombre que usa la API.
enum CampoDeRegistro {
  nombre('nombre'),
  apellido('apellido'),
  dni('dni'),
  fechaNacimiento('fecha_nacimiento'),
  correo('correo'),
  contrasena('contrasena');

  const CampoDeRegistro(this.clave);
  final String clave;

  static CampoDeRegistro? deLaApi(String clave) =>
      values.where((c) => c.clave == clave).firstOrNull;
}
