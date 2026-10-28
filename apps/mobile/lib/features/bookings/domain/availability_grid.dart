import 'slot.dart';

/// The slots of a space for a day and a duration, as the API computes them.
class AvailabilityGrid {
  const AvailabilityGrid({
    required this.date,
    required this.today,
    required this.opens,
    required this.slots,
    required this.unavailableCount,
  });

  /// Dates without time, in UTC: the club's day.
  final DateTime date;
  final DateTime today;

  /// False if the venue is closed that day.
  final bool opens;
  final List<Slot> slots;
  final int unavailableCount;

  bool get hasFree => slots.any((s) => s.available);
}
