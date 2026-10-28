/// The rules of a queried range that the API also validates
/// (`GET /espacios/disponibles`), to block the query before calling it. The messages are
/// the same.
library;

import '../../../common/dates.dart';
import '../../venues/domain/venue.dart';

const minHours = 1;
const maxHours = 4;
const daysInView = 7;

/// The on-the-hour value of `HH:MM`; `null` if it is not on the hour.
int? onTheHour(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2 || parts[1] != '00') return null;
  return int.tryParse(parts[0]);
}

/// «18:00».
String hhmm(int hour) => wholeHour(hour);

/// The error of [day] that does not depend on the venue: past or beyond the next days.
Map<String, String> dateErrors({required DateTime day, required DateTime now}) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final date = DateTime.utc(day.year, day.month, day.day);
  if (date.isBefore(today)) return {'fecha': 'La fecha tiene que ser futura'};
  if (!date.isBefore(today.add(const Duration(days: daysInView)))) {
    return {'fecha': 'Elegí un día de los próximos $daysInView'};
  }
  return {};
}

/// The errors per field (`fecha`, `desde`, `hasta`) of the range [from] to [to] (whole
/// hours; [to] 0 is midnight) on [day] at [venue], with [now] in club time.
Map<String, String> rangeErrors({
  required Venue venue,
  required DateTime day,
  required int from,
  required int to,
  required DateTime now,
}) {
  final errors = dateErrors(day: day, now: now);
  final today = DateTime.utc(now.year, now.month, now.day);
  final date = DateTime.utc(day.year, day.month, day.day);
  if (errors.isEmpty && !venue.days.contains(date.weekday)) {
    errors['fecha'] = 'La sede no abre ese día';
  }
  final end = to == 0 ? 24 : to;
  final opening = onTheHour(venue.opening) ?? 0;
  final closing = switch (onTheHour(venue.closing)) {
    0 || null => 24,
    final h => h,
  };
  if (end - from < minHours) {
    errors['hasta'] = 'La duración mínima es de una hora';
  } else if (end - from > maxHours) {
    errors['hasta'] = 'La duración máxima es de $maxHours horas';
  } else if (end > closing) {
    errors['hasta'] = 'La sede cierra a las ${venue.closing}';
  }
  if (from < opening) {
    errors['desde'] = 'La sede abre a las ${venue.opening}';
  } else if (!errors.containsKey('fecha') &&
      date == today &&
      from <= now.hour) {
    errors['desde'] = 'El horario tiene que ser futuro';
  }
  return errors;
}
