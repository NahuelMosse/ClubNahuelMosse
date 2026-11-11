import 'package:flutter_test/flutter_test.dart';

import 'support/admin.dart';
import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  Future<void> meetsGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  for (final dark in [true, false]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('the spaces panel meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        dark: dark,
        start: '/admin/spaces',
        api: apiRoutes({
          ...spaceRoutes(),
          'GET /spaces': (
            200,
            '{"spaces": [$spaceF5Json, $spaceTennisJson, $spaceCastelarJson]}',
          ),
        }),
      );
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets(
      'the space form with missing fields meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          start: '/admin/spaces/new',
          api: apiRoutes(spaceRoutes()),
        );
        await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
        await tester.tap(find.text('GUARDAR ESPACIO'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );

    testWidgets('the completed space form meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        dark: dark,
        start: '/admin/spaces/new',
        api: apiRoutes(spaceRoutes()),
      );
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await choose(tester, 'Tipo', 'Fútbol 5');
      await choose(tester, 'Condición', 'Al aire libre');
      await choose(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets('the venues panel meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        dark: dark,
        api: apiRoutes({
          'GET /venues': (
            200,
            '{"venues": [$venueMoronJson, $venueHaedoJson]}',
          ),
        }),
      );
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets(
      'the venue form with missing fields meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          start: '/admin/venues/new',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await tester.tap(find.text('GUARDAR SEDE'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );

    testWidgets('the time picker meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        dark: dark,
        start: '/admin/venues/new',
        api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
      );
      await tester.tap(find.bySemanticsLabel('Horario de apertura'));
      await tester.pumpAndSettle();
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets('the created venue meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        dark: dark,
        start: '/admin/venues/new',
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
      await meetsGuidelines(tester);
      semantics.dispose();
    });
  }
}
