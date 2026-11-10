import 'dart:io';
import 'dart:math' as math;

import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El contraste WCAG de [texto] sobre [fondo]; un texto translúcido se compone primero sobre el fondo.
double _contraste(Color texto, Color fondo) {
  final compuesto = Color.alphaBlend(texto, fondo);
  final (claro, oscuro) = (
    math.max(compuesto.computeLuminance(), fondo.computeLuminance()),
    math.min(compuesto.computeLuminance(), fondo.computeLuminance()),
  );
  return (claro + 0.05) / (oscuro + 0.05);
}

/// Las 33 variables de la colección `Color` del Figma: nombre, campo de [Palette], oscuro, claro.
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
    'cada color de la paleta oscura es el del Figma @RED-01-S1 @RED-05-S1',
    () {
      expect(_figma.map((v) => v.$1).toSet(), hasLength(33));
      for (final (nombre, campo, oscuro, _) in _figma) {
        expect(campo(Palette.dark), Color(oscuro), reason: nombre);
      }
    },
  );

  test(
    'cada color de la paleta clara es el del Figma @RED-01-S1 @RED-05-S1',
    () {
      for (final (nombre, campo, _, claro) in _figma) {
        expect(campo(Palette.light), Color(claro), reason: nombre);
      }
    },
  );

  test(
    'el textMuted oscuro es el #85858C del Figma y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01 @RED-05-ASM-01',
    () {
      const p = Palette.dark;
      expect(p.textMuted, const Color(0xFF85858C));
      for (final fondo in [p.bgBase, p.bgSurface, p.bgSurfaceRaised]) {
        expect(_contraste(p.textMuted, fondo), greaterThanOrEqualTo(4.5));
      }
    },
  );

  test(
    'el lima es el mismo en los dos modos y en modo claro la tinta del acento llega a 4,5:1 @RED-05-ASM-02',
    () {
      expect(Palette.light.accentBase, Palette.dark.accentBase);
      const p = Palette.light;
      expect(p.accentInk, isNot(p.accentBase));
      for (final fondo in [p.bgBase, p.bgSurface, p.bgSurfaceRaised]) {
        expect(_contraste(p.accentInk, fondo), greaterThanOrEqualTo(4.5));
      }
      for (final modo in [Palette.dark, Palette.light]) {
        expect(
          _contraste(modo.accentOn, modo.accentBase),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  test(
    'la etiqueta sobre foto, como «Fútbol 5», es del acento con su texto @RED-01-ASM-03 @RED-05-ASM-02',
    () {
      final codigo = File('lib/common/label.dart')
          .readAsLinesSync()
          .where((l) => !l.trimLeft().startsWith('//'))
          .join('\n');
      expect(codigo, contains('(p.accentBase, p.accentOn)'));
      expect(codigo, isNot(contains('Paleta.oscura')));
      expect(codigo, isNot(contains('Paleta.clara')));
      for (final modo in [Palette.dark, Palette.light]) {
        expect(
          _contraste(modo.accentOn, modo.accentBase),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
