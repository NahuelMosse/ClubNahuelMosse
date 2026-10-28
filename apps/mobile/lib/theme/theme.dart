import 'package:flutter/material.dart';

import 'tokens.dart';

/// The ten text styles of the prototype.
abstract final class Texts {
  static const display = TextStyle(
    fontFamily: 'Archivo Black',
    fontSize: 28,
    height: 34 / 28,
    letterSpacing: -0.28,
  );
  static const h1 = TextStyle(
    fontFamily: 'Archivo',
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 30 / 24,
    letterSpacing: -0.24,
  );
  static const h2 = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: -0.1,
  );
  static const title = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 22 / 17,
  );
  static const body = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
  );
  static const bodyStrong = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 22 / 15,
  );
  static const caption = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 18 / 13,
  );
  static const overline = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.88,
  );
  static const button = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: 0.3,
  );
  static const mono = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 13,
    height: 18 / 13,
  );
}

ThemeData _theme(Palette p, Brightness brightness) {
  return ThemeData(
    brightness: brightness,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: p.bgBase,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: p.accentBase,
      onPrimary: p.accentOn,
      secondary: p.accentInk,
      onSecondary: p.textInverse,
      error: p.stateDanger,
      onError: p.textInverse,
      surface: p.bgBase,
      onSurface: p.textPrimary,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accentInk,
      selectionColor: p.accentMuted,
      selectionHandleColor: p.accentInk,
    ),
    extensions: [p],
  );
}

final darkTheme = _theme(Palette.dark, Brightness.dark);
final lightTheme = _theme(Palette.light, Brightness.light);
