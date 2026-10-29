/// The state of a booking. [apiValue] is what the API sends; the interface text of each
/// state comes from the translations.
enum BookingStatus {
  active('activa'),
  completed('completada'),
  canceled('cancelada'),
  voided('anulada');

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
