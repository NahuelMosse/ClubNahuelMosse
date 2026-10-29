// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
/// The rules of a queried range that the API also validates
/// (`GET /espacios/disponibles`), to block the query before calling it. Each broken rule
/// is a [RangeProblem]; the screen writes it in the language of the device.
library;

import '../../../common/dates.dart';
import '../../venues/domain/venue.dart';

const minHours = 1;
const maxHours = 4;
const daysInView = 7;

/// What is wrong with a queried range.
enum RangeProblemKind {
  datePast,
  dateTooFar,
  venueClosedThatDay,
  tooShort,
  tooLong,
  venueCloses,
  venueOpens,
  timePast,
}

/// A broken rule of the range and the datum its message needs: the number of days in
/// view, the longest duration or the `HH:MM` the venue opens or closes at.
class RangeProblem {
  const RangeProblem(this.kind, [this.value]);

  final RangeProblemKind kind;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is RangeProblem && other.kind == kind && other.value == value;

  @override
  int get hashCode => Object.hash(kind, value);
}

/// The on-the-hour value of `HH:MM`; `null` if it is not on the hour.
int? onTheHour(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2 || parts[1] != '00') return null;
  return int.tryParse(parts[0]);
}

/// «18:00».
String hhmm(int hour) => wholeHour(hour);

/// The error of [day] that does not depend on the venue: past or beyond the next days.
Map<String, RangeProblem> dateErrors({
  required DateTime day,
  required DateTime now,
}) {
  final today = DateTime.utc(now.year, now.month, now.day);
  final date = DateTime.utc(day.year, day.month, day.day);
  if (date.isBefore(today)) {
    return {'fecha': const RangeProblem(RangeProblemKind.datePast)};
  }
  if (!date.isBefore(today.add(const Duration(days: daysInView)))) {
    return {
      'fecha': const RangeProblem(RangeProblemKind.dateTooFar, daysInView),
    };
  }
  return {};
}

/// The errors per field (`fecha`, `desde`, `hasta`) of the range [from] to [to] (whole
/// hours; [to] 0 is midnight) on [day] at [venue], with [now] in club time.
Map<String, RangeProblem> rangeErrors({
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
    errors['fecha'] = const RangeProblem(RangeProblemKind.venueClosedThatDay);
  }
  final end = to == 0 ? 24 : to;
  final opening = onTheHour(venue.opening) ?? 0;
  final closing = switch (onTheHour(venue.closing)) {
    0 || null => 24,
    final h => h,
  };
  if (end - from < minHours) {
    errors['hasta'] = const RangeProblem(RangeProblemKind.tooShort);
  } else if (end - from > maxHours) {
    errors['hasta'] = const RangeProblem(RangeProblemKind.tooLong, maxHours);
  } else if (end > closing) {
    errors['hasta'] = RangeProblem(RangeProblemKind.venueCloses, venue.closing);
  }
  if (from < opening) {
    errors['desde'] = RangeProblem(RangeProblemKind.venueOpens, venue.opening);
  } else if (!errors.containsKey('fecha') &&
      date == today &&
      from <= now.hour) {
    errors['desde'] = const RangeProblem(RangeProblemKind.timePast);
  }
  return errors;
}
