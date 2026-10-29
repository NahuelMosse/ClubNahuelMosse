/// The state of a booking. [apiValue] is what the API sends; the interface text of each
/// state comes from the translations.
enum BookingStatus {
  active('active'),
  completed('completed'),
  canceled('canceled'),
  voided('voided');

  const BookingStatus(this.apiValue);

  final String apiValue;

  /// The status the API calls [value]; `null` if it is not one of them.
  static BookingStatus? fromApi(String value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
