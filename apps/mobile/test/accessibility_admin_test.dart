import 'package:flutter_test/flutter_test.dart';

import 'support/admin.dart';
import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

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
      await mountAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/espacios',
        api: apiRoutes({
          ...spaceRoutes(),
          'GET /spaces': (
            200,
            '{"spaces": [$spaceF5Json, $spaceTennisJson, $spaceCastelarJson]}',
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
        await mountAdmin(
          tester,
          oscuro: oscuro,
          inicio: '/admin/espacios/nuevo',
          api: apiRoutes(spaceRoutes()),
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
      await mountAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/espacios/nuevo',
        api: apiRoutes(spaceRoutes()),
      );
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await choose(tester, 'Tipo', 'Fútbol 5');
      await choose(tester, 'Condición', 'Al aire libre');
      await choose(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el panel de sedes cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await mountAdmin(
        tester,
        oscuro: oscuro,
        api: apiRoutes({
          'GET /venues': (200, '{"venues": [$venueMoronJson, $venueHaedoJson]}'),
        }),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el alta con campos faltantes cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await mountAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/sedes/nueva',
        api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
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
      await mountAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/sedes/nueva',
        api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
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
      await mountAdmin(
        tester,
        oscuro: oscuro,
        inicio: '/admin/sedes/nueva',
        api: apiRoutes({
          'POST /venues': (201, venueHaedoJson),
          'GET /venues': (200, '{"venues": [$venueHaedoJson]}'),
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
      await choose(tester, 'Horario de apertura', '08:00');
      await choose(tester, 'Horario de cierre', '23:00');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('¡Sede creada!'), findsOneWidget);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }
}
