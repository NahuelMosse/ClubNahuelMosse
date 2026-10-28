import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/montar.dart';

Future<void> _montar(WidgetTester tester, ThemeData tema, Widget boton) =>
    montar(
      tester,
      Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: boton),
      ),
      tema: tema,
    );

/// El color que el botón pinta en [estados], tal como lo resuelve su estilo.
(Color?, Color?) _colores(WidgetTester tester, Set<WidgetState> estados) {
  final estilo = tester.widget<FilledButton>(find.byType(FilledButton)).style;
  return (
    estilo?.backgroundColor?.resolve(estados),
    estilo?.foregroundColor?.resolve(estados),
  );
}

/// Ninguna opacidad por debajo de 1 entre el botón y la raíz.
void _sinOpacidad(WidgetTester tester) {
  final opacidades = tester.widgetList<Opacity>(
    find.ancestor(
      of: find.byType(FilledButton),
      matching: find.byType(Opacity),
    ),
  );
  for (final o in opacidades) {
    expect(o.opacity, 1);
  }
}

void main() {
  testWidgets(
    'el botón principal deshabilitado es gris, con texto secundario y sin opacidad @RED-05-S3',
    (tester) async {
      for (final (tema, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        await _montar(
          tester,
          tema,
          const PrimaryButton(label: 'CONFIRMAR', onTap: null),
        );
        expect(_colores(tester, {WidgetState.disabled}), (
          p.stateDisabled,
          p.textSecondary,
        ));
        _sinOpacidad(tester);
      }
    },
  );

  testWidgets(
    'el botón atenuado usa el mismo gris y acepta el toque @RED-05-ASM-03',
    (tester) async {
      for (final (tema, p) in [
        (darkTheme, Palette.dark),
        (lightTheme, Palette.light),
      ]) {
        var toques = 0;
        await _montar(
          tester,
          tema,
          PrimaryButton(
            label: 'CONFIRMAR',
            onTap: () => toques++,
            dimmed: true,
          ),
        );
        expect(_colores(tester, {}), (p.stateDisabled, p.textSecondary));
        _sinOpacidad(tester);
        await tester.tap(find.text('CONFIRMAR'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(toques, 1);
      }
    },
  );
}
