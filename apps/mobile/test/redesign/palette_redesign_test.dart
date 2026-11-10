import 'dart:math' as math;

import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The WCAG contrast of [text] over [background]; a translucent text is composited first over the background.
double contrast(Color text, Color background) {
  final composite = Color.alphaBlend(text, background);
  final (light, dark) = (
    math.max(composite.computeLuminance(), background.computeLuminance()),
    math.min(composite.computeLuminance(), background.computeLuminance()),
  );
  return (light + 0.05) / (dark + 0.05);
}

/// The 32 variables of the Figma `Color` collection: name, [Palette] field, dark, light.
final List<(String, Color Function(Palette), int, int)> _figma = [
  ('bg/base', (p) => p.bgBase, 0xFF0B0A12, 0xFFFFFFFF),
  ('bg/surface', (p) => p.bgSurface, 0xFF17152A, 0xFFF4F4F6),
  ('bg/surface-raised', (p) => p.bgSurfaceRaised, 0xFF211E3A, 0xFFFFFFFF),
  ('bg/scrim', (p) => p.bgScrim, 0xA8000000, 0x73000000),
  ('bg/hero-from', (p) => p.bgHeroFrom, 0xFF2A1A55, 0xFFEEE8FF),
  ('bg/hero-to', (p) => p.bgHeroTo, 0xFF0B0A12, 0xFFFFFFFF),
  ('text/primary', (p) => p.textPrimary, 0xFFFFFFFF, 0xFF0A0A0B),
  ('text/secondary', (p) => p.textSecondary, 0xFFA9A3C2, 0xFF52525B),
  ('text/muted', (p) => p.textMuted, 0xFF87819F, 0xFF6B6B75),
  ('text/inverse', (p) => p.textInverse, 0xFF0B0A12, 0xFFFFFFFF),
  ('text/on-media', (p) => p.textOnMedia, 0xFFFFFFFF, 0xFFFFFFFF),
  ('text/on-media-muted', (p) => p.textOnMediaMuted, 0xFFDCD8EE, 0xFFD4D4D8),
  ('border/default', (p) => p.borderDefault, 0xFF2C2847, 0xFFE4E4E7),
  ('border/control', (p) => p.borderControl, 0xFF3E3961, 0xFF8A8A93),
  ('border/focus', (p) => p.borderFocus, 0xFFA88BFF, 0xFF6D3CF0),
  ('border/error', (p) => p.borderError, 0xFFFF4D6A, 0xFFD92D4A),
  ('accent/base', (p) => p.accentBase, 0xFF7C4DFF, 0xFF6D3CF0),
  ('accent/on', (p) => p.accentOn, 0xFFFFFFFF, 0xFFFFFFFF),
  ('accent/muted', (p) => p.accentMuted, 0x267C4DFF, 0x476D3CF0),
  ('accent/ink', (p) => p.accentInk, 0xFFD4FF3D, 0xFF5B2BD6),
  ('accent/edge', (p) => p.accentEdge, 0x007C4DFF, 0xFF6D3CF0),
  ('accent/on-media', (p) => p.accentOnMedia, 0xFFD4FF3D, 0xFFD4FF3D),
  ('state/danger', (p) => p.stateDanger, 0xFFFF4D6A, 0xFFD92D4A),
  ('state/danger-ink', (p) => p.stateDangerInk, 0xFFFF7B8E, 0xFFB4233D),
  ('state/danger-muted', (p) => p.stateDangerMuted, 0x2EFF4D6A, 0x1FDC2626),
  ('state/danger-strong', (p) => p.stateDangerStrong, 0xFFE02D4A, 0xFFB91C1C),
  ('state/success', (p) => p.stateSuccess, 0xFF3DD68C, 0xFF16A34A),
  ('state/success-ink', (p) => p.stateSuccessInk, 0xFF3DD68C, 0xFF15803D),
  ('state/success-muted', (p) => p.stateSuccessMuted, 0x2E3DD68C, 0x1F16A34A),
  ('state/warning', (p) => p.stateWarning, 0xFFFFB020, 0xFFD97706),
  ('state/warning-ink', (p) => p.stateWarningInk, 0xFFFFB020, 0xFFA85B00),
  ('state/disabled', (p) => p.stateDisabled, 0xFF3E3961, 0xFFD4D4D8),
];

void main() {
  test('the Figma table has its 32 variables', () {
    expect(_figma.map((v) => v.$1).toSet(), hasLength(32));
  });

  test(
    'every color of the dark palette is the Figma one, except textMuted @RED-01-S1',
    () {
      for (final (name, field, dark, _) in _figma) {
        if (name == 'text/muted') continue;
        expect(field(Palette.dark), Color(dark), reason: name);
      }
    },
  );

  test('every color of the light palette is the Figma one @RED-01-S1', () {
    for (final (name, field, _, light) in _figma) {
      expect(field(Palette.light), Color(light), reason: name);
    }
  });

  test(
    'the dark textMuted is #8C86A4 and reaches 4.5:1 over the three surfaces @RED-01-ASM-01',
    () {
      const p = Palette.dark;
      expect(p.textMuted, const Color(0xFF8C86A4));
      for (final background in [p.bgBase, p.bgSurface, p.bgSurfaceRaised]) {
        expect(contrast(p.textMuted, background), greaterThanOrEqualTo(4.5));
      }
    },
  );

  test(
    'every contrast pair of the palette reaches 4.5:1 in both modes @RED-01-ASM-02',
    () {
      const black = Color(0xFF000000);
      const white = Color(0xFFFFFFFF);
      for (final (mode, p) in [
        ('oscuro', Palette.dark),
        ('claro', Palette.light),
      ]) {
        final pairs = <String, (Color, Color)>{
          for (final (text, t) in [
            ('textPrimary', p.textPrimary),
            ('textSecondary', p.textSecondary),
            ('textMuted', p.textMuted),
            ('accentInk', p.accentInk),
          ])
            for (final (background, f) in [
              ('bgBase', p.bgBase),
              ('bgSurface', p.bgSurface),
              ('bgSurfaceRaised', p.bgSurfaceRaised),
            ])
              '$text sobre $background': (t, f),
          'accentOn sobre accentBase': (p.accentOn, p.accentBase),
          'stateDangerInk sobre bgBase': (p.stateDangerInk, p.bgBase),
          'blanco sobre stateDangerStrong': (white, p.stateDangerStrong),
          'textOnMedia sobre negro': (p.textOnMedia, black),
          'accentOnMedia sobre negro': (p.accentOnMedia, black),
        };
        for (final MapEntry(key: pair, value: (text, background))
            in pairs.entries) {
          expect(
            contrast(text, background),
            greaterThanOrEqualTo(4.5),
            reason: '$pair in mode $mode',
          );
        }
      }
    },
  );
}
