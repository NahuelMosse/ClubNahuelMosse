import 'dart:math' as math;

import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// El contraste WCAG entre dos colores opacos.
double contraste(Color a, Color b) {
  final (claro, oscuro) = (
    math.max(a.computeLuminance(), b.computeLuminance()),
    math.min(a.computeLuminance(), b.computeLuminance()),
  );
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  for (final (modo, p) in [
    ('oscuro', Paleta.oscura),
    ('claro', Paleta.clara),
  ]) {
    test('los textos llegan a 4,5:1 sobre las superficies en modo $modo', () {
      for (final (nombre, texto) in [
        ('textPrimary', p.textPrimary),
        ('textSecondary', p.textSecondary),
        ('textMuted', p.textMuted),
      ]) {
        for (final (fondo, superficie) in [
          ('bgBase', p.bgBase),
          ('bgSurface', p.bgSurface),
          ('bgSurfaceRaised', p.bgSurfaceRaised),
        ]) {
          expect(
            contraste(texto, superficie),
            greaterThanOrEqualTo(4.5),
            reason: '$nombre sobre $fondo',
          );
        }
      }
    });
  }
}
