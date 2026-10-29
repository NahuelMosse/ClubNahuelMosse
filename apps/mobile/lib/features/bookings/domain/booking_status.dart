/// The state of a booking. [apiValue] is what the API sends; [label] is what people read.
enum BookingStatus {
  active('active', 'Activa'),
  completed('completed', 'Completada'),
  canceled('canceled', 'Cancelada'),
  voided('voided', 'Anulada');

  const BookingStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// The status the API calls [value]; `null` if it is not one of them.
  static BookingStatus? fromApi(String value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    return null;
  }
}
