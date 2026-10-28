import '../domain/availability_grid.dart';
import '../domain/slot.dart';

/// The slot in [json]; `null` if it is not one.
Slot? slotFromJson(Object? json) => switch (json) {
  {
    'inicio': final String start,
    'fin': final String end,
    'disponible': final bool available,
  } =>
    Slot(start: start, end: end, available: available),
  _ => null,
};

/// The grid in [json]; `null` if it is not one.
AvailabilityGrid? availabilityGridFromJson(Object? json) {
  if (json case {
    'fecha': final String date,
    'hoy': final String today,
    'abre': final bool opens,
    'franjas': final List<Object?> list,
    'no_disponibles': final int unavailableCount,
  }) {
    final day = _day(date);
    final todayDate = _day(today);
    final slots = [for (final s in list) slotFromJson(s)];
    if (day == null || todayDate == null || slots.contains(null)) return null;
    return AvailabilityGrid(
      date: day,
      today: todayDate,
      opens: opens,
      slots: [...slots.nonNulls],
      unavailableCount: unavailableCount,
    );
  }
  return null;
}

DateTime? _day(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? null : DateTime.utc(d.year, d.month, d.day);
}
