import 'dart:math' as math;

import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The WCAG contrast between two opaque colors.
double contrast(Color a, Color b) {
  final (lighter, darker) = (
    math.max(a.computeLuminance(), b.computeLuminance()),
    math.min(a.computeLuminance(), b.computeLuminance()),
  );
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  for (final (mode, p) in [('dark', Palette.dark), ('light', Palette.light)]) {
    test('texts reach 4.5:1 over the surfaces in $mode mode', () {
      for (final (name, text) in [
        ('textPrimary', p.textPrimary),
        ('textSecondary', p.textSecondary),
        ('textMuted', p.textMuted),
      ]) {
        for (final (background, surface) in [
          ('bgBase', p.bgBase),
          ('bgSurface', p.bgSurface),
          ('bgSurfaceRaised', p.bgSurfaceRaised),
        ]) {
          expect(
            contrast(text, surface),
            greaterThanOrEqualTo(4.5),
            reason: '$name over $background',
          );
        }
      }
    });

    test('the text of a red button reaches 4.5:1 in $mode mode', () {
      final text = textOn(p.stateDanger, p);
      expect(contrast(text, p.stateDanger), greaterThanOrEqualTo(4.5));
    });
  }
}
