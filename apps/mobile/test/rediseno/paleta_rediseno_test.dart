import 'dart:math' as math;

import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El contraste WCAG de [texto] sobre [fondo]; un texto translúcido se compone primero sobre el fondo.
double contraste(Color texto, Color fondo) {
  final compuesto = Color.alphaBlend(texto, fondo);
  final (claro, oscuro) = (
    math.max(compuesto.computeLuminance(), fondo.computeLuminance()),
    math.min(compuesto.computeLuminance(), fondo.computeLuminance()),
  );
  return (claro + 0.05) / (oscuro + 0.05);
}

/// Las 32 variables de la colección `Color` del Figma: nombre, campo de [Paleta], oscuro, claro.
final List<(String, Color Function(Paleta), int, int)> _figma = [
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
  test('la tabla del Figma tiene sus 32 variables', () {
    expect(_figma.map((v) => v.$1).toSet(), hasLength(32));
  });

  test(
    'cada color de la paleta oscura es el del Figma, salvo textMuted @RED-01-S1',
    () {
      for (final (nombre, campo, oscuro, _) in _figma) {
        if (nombre == 'text/muted') continue;
        expect(campo(Paleta.oscura), Color(oscuro), reason: nombre);
      }
    },
  );

  test('cada color de la paleta clara es el del Figma @RED-01-S1', () {
    for (final (nombre, campo, _, claro) in _figma) {
      expect(campo(Paleta.clara), Color(claro), reason: nombre);
    }
  });

  test(
    'el textMuted oscuro es #8C86A4 y llega a 4,5:1 sobre las tres superficies @RED-01-ASM-01',
    () {
      const p = Paleta.oscura;
      expect(p.textMuted, const Color(0xFF8C86A4));
      for (final fondo in [p.bgBase, p.bgSurface, p.bgSurfaceRaised]) {
        expect(contraste(p.textMuted, fondo), greaterThanOrEqualTo(4.5));
      }
    },
  );

  test(
    'cada par de contraste de la paleta llega a 4,5:1 en los dos modos @RED-01-ASM-02',
    () {
      const negro = Color(0xFF000000);
      const blanco = Color(0xFFFFFFFF);
      for (final (modo, p) in [
        ('oscuro', Paleta.oscura),
        ('claro', Paleta.clara),
      ]) {
        final pares = <String, (Color, Color)>{
          for (final (texto, t) in [
            ('textPrimary', p.textPrimary),
            ('textSecondary', p.textSecondary),
            ('textMuted', p.textMuted),
            ('accentInk', p.accentInk),
          ])
            for (final (fondo, f) in [
              ('bgBase', p.bgBase),
              ('bgSurface', p.bgSurface),
              ('bgSurfaceRaised', p.bgSurfaceRaised),
            ])
              '$texto sobre $fondo': (t, f),
          'accentOn sobre accentBase': (p.accentOn, p.accentBase),
          'stateDangerInk sobre bgBase': (p.stateDangerInk, p.bgBase),
          'blanco sobre stateDangerStrong': (blanco, p.stateDangerStrong),
          'textOnMedia sobre negro': (p.textOnMedia, negro),
          'accentOnMedia sobre negro': (p.accentOnMedia, negro),
        };
        for (final MapEntry(key: par, value: (texto, fondo)) in pares.entries) {
          expect(
            contraste(texto, fondo),
            greaterThanOrEqualTo(4.5),
            reason: '$par en modo $modo',
          );
        }
      }
    },
  );
}
