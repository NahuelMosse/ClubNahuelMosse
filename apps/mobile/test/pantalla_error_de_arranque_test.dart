import 'package:clubnahuelmosse/comun/pantalla_error_de_arranque.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

void main() {
  for (final (modo, tema) in [('oscuro', temaOscuro), ('claro', temaClaro)]) {
    for (final sinRed in [true, false]) {
      testWidgets(
        'el error de arranque ${sinRed ? 'sin red' : 'sin servidor'} cumple las pautas de accesibilidad en modo $modo @INT-01-S3',
        (tester) async {
          final semantica = tester.ensureSemantics();
          await montar(
            tester,
            PantallaErrorDeArranque(sinRed: sinRed, alReintentar: () {}),
            tema: tema,
          );

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
          expect(find.bySemanticsLabel('REINTENTAR'), findsOneWidget);
          semantica.dispose();
        },
      );
    }
  }

  testWidgets(
    'con el texto al 200 % el error de arranque se lee entero @INT-01-S3',
    (tester) async {
      await montar(
        tester,
        PantallaErrorDeArranque(sinRed: true, alReintentar: () {}),
        tema: temaOscuro,
        tamano: const Size(360, 640),
        escalaTexto: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('REINTENTAR'), findsOneWidget);
    },
  );
}
