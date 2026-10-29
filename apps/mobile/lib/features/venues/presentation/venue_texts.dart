import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/venue.dart';

/// «Lunes a sábado» in the language of [l].
String openDaysText(AppLocalizations l, OpenDays option) => switch (option) {
  OpenDays.mondayToSunday => l.venueDaysMondayToSunday,
  OpenDays.mondayToSaturday => l.venueDaysMondayToSaturday,
  OpenDays.mondayToFriday => l.venueDaysMondayToFriday,
};

/// The open days of a venue: one of the ranges, or the short day names («Mon, Wed»).
String weekdaysText(AppLocalizations l, WeekdaysLabel label) {
  final option = label.option;
  if (option != null) return openDaysText(l, option);
  final names = DateFormat.E(l.localeName);
  return [
    for (final day in label.days)
      _capitalized(names.format(DateTime.utc(2024, 1, day))),
  ].join(', ');
}

// 2024-01-01 is a Monday, so day 1 to 7 maps to Monday to Sunday.
String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
