import 'dart:ui';

const supportedLanguages = [Locale('en'), Locale('es')];

Locale resolveLanguage(List<Locale>? device, Iterable<Locale> supported) =>
    const Locale('es');

void useLanguage(Locale language) {}

String currentLanguage() => 'es';
