/// The fields of a new space.
enum NewSpaceField {
  venue('sede_id'),
  sport('deporte'),
  type('tipo'),
  roofing('techada'),
  lighting('iluminada'),
  price('precio_por_hora');

  const NewSpaceField(this.apiKey);

  /// The field name in the API.
  final String apiKey;
}
