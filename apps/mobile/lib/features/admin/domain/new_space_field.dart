/// The fields of a new space.
enum NewSpaceField {
  venue('venue_id'),
  sport('sport'),
  type('kind'),
  roofing('covered'),
  lighting('lit'),
  price('price_per_hour');

  const NewSpaceField(this.apiKey);

  /// The field name in the API.
  final String apiKey;
}
