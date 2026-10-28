import 'dart:math' as math;

import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';

double _contraste(Color texto, Color fondo) {
  final compuesto = Color.alphaBlend(texto, fondo);
  final (claro, oscuro) = (
    math.max(compuesto.computeLuminance(), fondo.computeLuminance()),
    math.min(compuesto.computeLuminance(), fondo.computeLuminance()),
  );
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  testWidgets(
    'el botón atenuado baja sólo el fondo del lima, deja el texto principal y acepta el toque @RED-05-ASM-03',
    (tester) async {
      for (final (tema, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        var toques = 0;
        await montar(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'CONFIRMAR',
                onTap: () => toques++,
                dimmed: true,
              ),
            ),
          ),
          tema: tema,
        );
        final estilo = tester
            .widget<FilledButton>(find.byType(FilledButton))
            .style;
        final fondo = estilo?.backgroundColor?.resolve({});
        final texto = estilo?.foregroundColor?.resolve({});

        expect(fondo, p.accentBase.withValues(alpha: 0.4));
        expect(texto, p.textPrimary);
        expect(
          _contraste(
            p.textPrimary,
            Color.alphaBlend(p.accentBase.withValues(alpha: 0.4), p.bgBase),
          ),
          greaterThanOrEqualTo(4.5),
        );
        for (final o in tester.widgetList<Opacity>(
          find.ancestor(
            of: find.byType(FilledButton),
            matching: find.byType(Opacity),
          ),
        )) {
          expect(o.opacity, 1);
        }
        await tester.tap(find.text('CONFIRMAR'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(toques, 1);
      }
    },
  );
}
