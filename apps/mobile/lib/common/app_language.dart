import 'dart:ui';

import 'package:intl/intl.dart';

/// The languages of the app. The first is the default: a device in any other language
/// shows the app in English.
const supportedLanguages = [Locale('en'), Locale('es')];

/// The language of the app for a device: the first language of its list decides, whatever
/// its region; one the app does not have gets the default, even if a supported one comes
/// further down the list.
Locale resolveLanguage(List<Locale>? device, Iterable<Locale> supported) {
  final fallback = supported.first;
  if (device == null || device.isEmpty) return fallback;
  final first = device.first.languageCode;
  return supported.firstWhere(
    (language) => language.languageCode == first,
    orElse: () => fallback,
  );
}

/// Makes [language] the one the dates, days and numbers are written in.
void useLanguage(Locale language) => Intl.defaultLocale = language.languageCode;

/// The language code (`en`, `es`) that [useLanguage] last set; English before any.
String currentLanguage() => Intl.defaultLocale ?? 'en';
