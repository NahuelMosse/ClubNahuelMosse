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

    testWidgets('el panel de espacios cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/espacios',
        api: apiRutas({
          ...rutasDeEspacios(),
          'GET /spaces': (
            200,
            '{"spaces": [$espacioF5Json, $espacioTenisJson, $espacioCastelarJson]}',
          ),
        }),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets(
      'el alta de espacio con faltantes cumple las guías en modo $modo',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await montarAdmin(
          tester,
          oscuro: oscuro,
          inicio: '/admin/espacios/nuevo',
          api: apiRutas(rutasDeEspacios()),
        );
        await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
        await tester.tap(find.text('GUARDAR ESPACIO'));
        await tester.pumpAndSettle();
        await cumpleLasGuias(tester);
        semantica.dispose();
      },
    );

    testWidgets('el alta de espacio completa cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/espacios/nuevo',
        api: apiRutas(rutasDeEspacios()),
      );
      await elegir(tester, 'Sede', 'Sede Morón');
      await elegir(tester, 'Deporte', 'Fútbol');
      await elegir(tester, 'Tipo', 'Fútbol 5');
      await elegir(tester, 'Condición', 'Al aire libre');
      await elegir(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el panel de sedes cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        oscuro: oscuro,
        api: apiRutas({
          'GET /venues': (200, '{"venues": [$sedeMoronJson, $sedeHaedoJson]}'),
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
        api: apiRutas({'GET /venues': (200, '{"venues": []}')}),
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
        api: apiRutas({'GET /venues': (200, '{"venues": []}')}),
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
          'POST /venues': (201, sedeHaedoJson),
          'GET /venues': (200, '{"venues": [$sedeHaedoJson]}'),
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
