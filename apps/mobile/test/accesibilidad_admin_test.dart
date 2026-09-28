import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  for (final oscuro in [true, false]) {
    final modo = oscuro ? 'oscuro' : 'claro';

    testWidgets('el panel de sedes cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        api: apiRutas({
          'GET /sedes': (200, '{"sedes": [$sedeMoronJson, $sedeHaedoJson]}'),
        }),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el alta con campos faltantes cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
      );
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el selector de horario cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
      );
      await tester.tap(find.bySemanticsLabel('Horario de apertura'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('la sede creada cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({
          'POST /sedes': (201, sedeHaedoJson),
          'GET /sedes': (200, '{"sedes": [$sedeHaedoJson]}'),
        }),
      );
      await tester.enterText(
        find.bySemanticsLabel('Nombre de la sede'),
        'Sede Haedo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Dirección'),
        'Av. Vergara 1850',
      );
      await elegir(tester, 'Horario de apertura', '08:00');
      await elegir(tester, 'Horario de cierre', '23:00');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('¡Sede creada!'), findsOneWidget);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }
}
