const venueNameMaxLength = 60;
const venueAddressMaxLength = 80;
final _streetAndNumber = RegExp(r'^.*\S\s+(\d{1,6})$');

/// `HH:MM` to the hour; `null` if it is not a whole hour.
int? parseWholeHour(String hhmm) => switch (hhmm.split(':')) {
  [final h, '00'] => int.tryParse(h),
  _ => null,
};

String? venueNameError(String name) =>
    name.trim().isEmpty ? 'El nombre es obligatorio' : null;

String? venueAddressError(String text) {
  final address = text.trim();
  if (address.isEmpty) return 'La dirección es obligatoria';
  final number = _streetAndNumber.firstMatch(address)?.group(1);
  return number != null && int.parse(number) > 0
      ? null
      : 'Escribí la calle y la altura';
}

String? opensAtError(int? opensAt) =>
    opensAt == null ? 'El horario de apertura es obligatorio' : null;

String? closesAtError({required int? closesAt, required int? opensAt}) {
  if (closesAt == null) return 'El horario de cierre es obligatorio';
  // Closing at 00:00 means closing at midnight.
  if (opensAt != null && closesAt != 0 && closesAt <= opensAt) {
    return 'El cierre tiene que ser después de la apertura';
  }
  return null;
}
