// kit-boundary: the app-wide widget kit, shared by every feature.
// kit-shape: a widget with its private parts kept together.
/// Dates, times, days and the DNI as the app shows them, in the language of the app.
/// `intl` returns names in lower case; here they get their initial capital or are
/// upper-cased. The `en` and `es` data are loaded by `initializeDateFormatting` at
/// startup and in tests.
library;

import 'dart:ui';

import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import 'app_language.dart';

String get _locale => currentLanguage();

/// The DNI is written with Spanish thousands dots in every language.
const _dniLocale = 'es';

String _capitalize(String text) => toBeginningOfSentenceCase(text, _locale)!;

/// «Jueves» / «Thursday».
String weekdayName(DateTime day) =>
    _capitalize(DateFormat.EEEE(_locale).format(day));

/// «JUE» / «THU».
String weekdayAbbreviation(DateTime day) =>
    DateFormat.E(_locale).format(day).toUpperCase();

/// «Jue» / «Thu» for the weekday [day], from 1 (Monday) to 7 (Sunday).
String shortWeekdayName(int day) =>
    _capitalize(DateFormat.E(_locale).format(DateTime(2024, 1, day)));

/// «Jue 12» / «Thu 12».
String shortDay(DateTime day) =>
    _capitalize(DateFormat('E d', _locale).format(day));

/// «Jue 12 nov» / «Thu 12 Nov». `intl` abbreviates September as «sept»; here months are always three letters.
String shortDate(DateTime day) =>
    '${shortDay(day)} ${DateFormat.MMMM(_locale).format(day).substring(0, 3)}';

/// «Jue 12 de noviembre» / «Thu 12 November».
String longDate(DateTime day) {
  final connector = _locale == 'es' ? ' de ' : ' ';
  final month = DateFormat.MMMM(_locale).format(day);
  return '${shortDay(day)}$connector$month';
}

/// «1 hora», «3 horas» / «1 hour», «3 hours».
String duration(int hours) =>
    lookupAppLocalizations(Locale(_locale)).commonDuration(hours);

/// «09:05».
String shortTime(DateTime moment) =>
    DateFormat('HH:mm', _locale).format(moment);

/// «21:00 – 22:00».
String timeRange(DateTime start, DateTime end) =>
    '${shortTime(start)} – ${shortTime(end)}';

/// «18:00»; [hour] 24 is midnight.
String wholeHour(int hour) => shortTime(DateTime(2000, 1, 1, hour % 24));

/// «04», «12»: the number with two digits.
String twoDigits(int n) => NumberFormat('00', _locale).format(n);

/// The date in the format the API expects (`YYYY-MM-DD`).
String isoDate(DateTime date) => DateFormat('yyyy-MM-dd', _locale).format(date);

/// The date to read, as in the profile (`DD/MM/YYYY`).
String readableDate(DateTime date) =>
    DateFormat('dd/MM/yyyy', _locale).format(date);

/// The day and month of the date (`DD/MM`).
String dayAndMonth(DateTime date) => DateFormat('dd/MM', _locale).format(date);

/// The date as it is typed in the field (`DD / MM / YYYY`).
String formatDate(DateTime date) =>
    DateFormat('dd / MM / yyyy', _locale).format(date);

/// The DNI without dots or spaces.
String normalizeDni(String dni) => dni.replaceAll(RegExp(r'[.\s]'), '');

/// The DNI with thousands dots, as printed on the document: `42.118.507`. If it is not
/// only digits it is shown as it arrives.
String readableDni(String dni) {
  final digits = normalizeDni(dni);
  final number = RegExp(r'^[0-9]+$').hasMatch(digits)
      ? int.tryParse(digits)
      : null;
  if (number == null) return dni;
  return NumberFormat.decimalPattern(_dniLocale).format(number);
}
