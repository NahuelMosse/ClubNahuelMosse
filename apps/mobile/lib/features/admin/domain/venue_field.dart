/// The fields of a venue form; each one carries the key the API uses for it.
enum VenueField {
  name('name'),
  address('address'),
  opensAt('opens_at'),
  closesAt('closes_at'),
  openDays('open_days');

  const VenueField(this.apiKey);

  /// The field name in the API.
  final String apiKey;
}
