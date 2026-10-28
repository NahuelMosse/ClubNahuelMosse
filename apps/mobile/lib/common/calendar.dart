// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
import 'package:flutter/material.dart';

import 'clock.dart';

/// The calendar to pick a birth date: any day before today at the club.
///
/// [proposed] is the date it opens on; if it falls outside the range it is moved to the edge,
/// because the Material calendar does not open on a date that cannot be picked.
Future<DateTime?> pickBirthDate(BuildContext context, DateTime proposed) {
  final today = clubNow();
  final last = DateTime(today.year, today.month, today.day - 1);
  final first = proposed.isBefore(DateTime(1900)) ? proposed : DateTime(1900);
  return showDatePicker(
    context: context,
    initialDate: proposed.isAfter(last) ? last : proposed,
    firstDate: first,
    lastDate: last,
  );
}

/// The calendar of the [days] that follow from [today], with [proposed] marked if it falls
/// among them.
Future<DateTime?> pickUpcomingDay(
  BuildContext context, {
  required DateTime today,
  required int days,
  DateTime? proposed,
}) {
  final first = DateTime(today.year, today.month, today.day);
  final last = DateTime(today.year, today.month, today.day + days - 1);
  final picked = proposed == null
      ? first
      : DateTime(proposed.year, proposed.month, proposed.day);
  return showDatePicker(
    context: context,
    initialDate: picked.isBefore(first) || picked.isAfter(last)
        ? first
        : picked,
    firstDate: first,
    lastDate: last,
  );
}
