/// Los campos del alta de un espacio.
enum CampoDeAltaDeEspacio {
  sede('sede_id'),
  deporte('deporte'),
  tipo('tipo'),
  condicion('techada'),
  iluminacion('iluminada'),
  precio('precio_por_hora');

  const CampoDeAltaDeEspacio(this.clave);

  /// El nombre del campo en la API.
  final String clave;
}
