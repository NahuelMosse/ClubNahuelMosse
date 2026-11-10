import 'dart:io';
import 'dart:math' as math;

import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The WCAG contrast of [text] over [background]; a translucent text is composited first over the background.
double _contrast(Color text, Color background) {
  final composite = Color.alphaBlend(text, background);
  final (light, dark) = (
    math.max(composite.computeLuminance(), background.computeLuminance()),
    math.min(composite.computeLuminance(), background.computeLuminance()),
  );
  return (light + 0.05) / (dark + 0.05);
}

/// The 33 variables of the Figma `Color` collection: name, [Palette] field, dark, light.
final List<(String, Color Function(Palette), int, int)> _figma = [
  ('bg/base', (p) => p.bgBase, 0xFF0A0A0B, 0xFFFFFFFF),
  ('bg/surface', (p) => p.bgSurface, 0xFF141416, 0xFFF4F4F6),
  ('bg/surface-raised', (p) => p.bgSurfaceRaised, 0xFF1E1E21, 0xFFFFFFFF),
  ('bg/scrim', (p) => p.bgScrim, 0xA8000000, 0x73000000),
  ('bg/hero-from', (p) => p.bgHeroFrom, 0xFF16301F, 0xFFEEF9D6),
  ('bg/hero-to', (p) => p.bgHeroTo, 0xFF0A0A0B, 0xFFFFFFFF),
  ('text/primary', (p) => p.textPrimary, 0xFFFFFFFF, 0xFF0A0A0B),
  ('text/secondary', (p) => p.textSecondary, 0xFFA1A1AA, 0xFF52525B),
  ('text/muted', (p) => p.textMuted, 0xFF85858C, 0xFF6B6B75),
  ('text/inverse', (p) => p.textInverse, 0xFF0A0A0B, 0xFFFFFFFF),
  ('text/on-media', (p) => p.textOnMedia, 0xFFFFFFFF, 0xFFFFFFFF),
  ('text/on-media-muted', (p) => p.textOnMediaMuted, 0xFFD4D4D8, 0xFFD4D4D8),
  ('border/default', (p) => p.borderDefault, 0xFF2A2A2E, 0xFFE4E4E7),
  ('border/control', (p) => p.borderControl, 0xFF64646E, 0xFF8A8A93),
  ('border/focus', (p) => p.borderFocus, 0xFFD4FF3D, 0xFF5C7A00),
  ('border/error', (p) => p.borderError, 0xFFFF4D6A, 0xFFD92D4A),
  ('accent/base', (p) => p.accentBase, 0xFFD4FF3D, 0xFFD4FF3D),
  ('accent/on', (p) => p.accentOn, 0xFF0A0A0B, 0xFF0A0A0B),
  ('accent/muted', (p) => p.accentMuted, 0x24D4FF3D, 0x1F5C7A00),
  ('accent/ink', (p) => p.accentInk, 0xFFD4FF3D, 0xFF4D6600),
  ('accent/edge', (p) => p.accentEdge, 0x00D4FF3D, 0xFF5C7A00),
  ('accent/on-media', (p) => p.accentOnMedia, 0xFFD4FF3D, 0xFFD4FF3D),
  ('accent/libre', (p) => p.accentFree, 0xFF6B8A1C, 0xFF8DB31F),
  ('state/danger', (p) => p.stateDanger, 0xFFFF4D6A, 0xFFD92D4A),
  ('state/danger-ink', (p) => p.stateDangerInk, 0xFFFF7B8E, 0xFFB4233D),
  ('state/danger-muted', (p) => p.stateDangerMuted, 0x2EFF4D6A, 0x1FDC2626),
  ('state/danger-strong', (p) => p.stateDangerStrong, 0xFFE02D4A, 0xFFB91C1C),
  ('state/success', (p) => p.stateSuccess, 0xFF3DD68C, 0xFF16A34A),
  ('state/success-ink', (p) => p.stateSuccessInk, 0xFF3DD68C, 0xFF15803D),
  ('state/success-muted', (p) => p.stateSuccessMuted, 0x2E3DD68C, 0x1F16A34A),
  ('state/warning', (p) => p.stateWarning, 0xFFFFB020, 0xFFD97706),
  ('state/warning-ink', (p) => p.stateWarningInk, 0xFFFFB020, 0xFFA85B00),
  ('state/disabled', (p) => p.stateDisabled, 0xFF3A3A40, 0xFFD4D4D8),
];

void main() {
  test(
    'every color of the dark palette is the Figma one @RED-01-S1 @RED-05-S1',
    () {
      expect(_figma.map((v) => v.$1).toSet(), hasLength(33));
      for (final (name, field, dark, _) in _figma) {
        expect(field(Palette.dark), Color(dark), reason: name);
      }
    },
  );

  test(
    'every color of the light palette is the Figma one @RED-01-S1 @RED-05-S1',
    () {
      for (final (name, field, _, light) in _figma) {
        expect(field(Palette.light), Color(light), reason: name);
      }
    },
  );

  test(
    'the dark textMuted is the Figma #85858C and reaches 4.5:1 over the three surfaces @RED-01-ASM-01 @RED-05-ASM-01',
    () {
      const p = Palette.dark;
      expect(p.textMuted, const Color(0xFF85858C));
      for (final background in [p.bgBase, p.bgSurface, p.bgSurfaceRaised]) {
        expect(_contrast(p.textMuted, background), greaterThanOrEqualTo(4.5));
      }
    },
  );

  test(
    'the lime is the same in both modes and in light mode the accent ink reaches 4.5:1 @RED-05-ASM-02',
    () {
      expect(Palette.light.accentBase, Palette.dark.accentBase);
      const p = Palette.light;
      expect(p.accentInk, isNot(p.accentBase));
      for (final background in [p.bgBase, p.bgSurface, p.bgSurfaceRaised]) {
        expect(_contrast(p.accentInk, background), greaterThanOrEqualTo(4.5));
      }
      for (final mode in [Palette.dark, Palette.light]) {
        expect(
          _contrast(mode.accentOn, mode.accentBase),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  test(
    'the on-photo label, like «Fútbol 5», is the accent with its text @RED-01-ASM-03 @RED-05-ASM-02',
    () {
      final code = File('lib/common/label.dart')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(code, contains('(p.accentBase, p.accentOn)'));
      expect(code, isNot(contains('Paleta.oscura')));
      expect(code, isNot(contains('Paleta.clara')));
      for (final mode in [Palette.dark, Palette.light]) {
        expect(
          _contrast(mode.accentOn, mode.accentBase),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
