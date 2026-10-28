/// The fields of a venue form; each one carries the key the API uses for it.
enum VenueField {
  name('nombre'),
  address('direccion'),
  opensAt('apertura'),
  closesAt('cierre'),
  openDays('dias');

  const VenueField(this.apiKey);

  /// The field name in the API.
  final String apiKey;
}
