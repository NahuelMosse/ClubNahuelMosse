import 'venue_problem.dart';

const venueNameMaxLength = 60;
const venueAddressMaxLength = 80;
final _streetAndNumber = RegExp(r'^.*\S\s+(\d{1,6})$');

/// `HH:MM` to the hour; `null` if it is not a whole hour.
int? parseWholeHour(String hhmm) => switch (hhmm.split(':')) {
  [final h, '00'] => int.tryParse(h),
  _ => null,
};

VenueProblem? venueNameProblem(String name) =>
    name.trim().isEmpty ? VenueProblem.nameRequired : null;

VenueProblem? venueAddressProblem(String text) {
  final address = text.trim();
  if (address.isEmpty) return VenueProblem.addressRequired;
  final number = _streetAndNumber.firstMatch(address)?.group(1);
  return number != null && int.parse(number) > 0
      ? null
      : VenueProblem.addressStreetAndNumber;
}

VenueProblem? opensAtProblem(int? opensAt) =>
    opensAt == null ? VenueProblem.opensAtRequired : null;

VenueProblem? closesAtProblem({
  required int? closesAt,
  required int? opensAt,
}) {
  if (closesAt == null) return VenueProblem.closesAtRequired;
  // Closing at 00:00 means closing at midnight.
  if (opensAt != null && closesAt != 0 && closesAt <= opensAt) {
    return VenueProblem.closesBeforeOpens;
  }
  return null;
}
