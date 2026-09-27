import 'package:flutter/material.dart';

import 'tokens.dart';

/// Los diez estilos de texto del prototipo.
abstract final class Textos {
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
  static const titulo = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 22 / 17,
  );
  static const cuerpo = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
  );
  static const cuerpoFuerte = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 22 / 15,
  );
  static const leyenda = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 18 / 13,
  );
  static const sobretitulo = TextStyle(
    fontFamily: 'Inter',
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.88,
  );
  static const boton = TextStyle(
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

ThemeData _tema(Paleta p, Brightness brillo) {
  return ThemeData(
    brightness: brillo,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: p.bgBase,
    colorScheme: ColorScheme(
      brightness: brillo,
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

final temaOscuro = _tema(Paleta.oscura, Brightness.dark);
final temaClaro = _tema(Paleta.clara, Brightness.light);
