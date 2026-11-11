import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {
    '320': Size(320, 568),
    '360': Size(360, 800),
    '430': Size(430, 932),
  };
  const modes = {'dark': true, 'light': false};
  const duplicate =
      '{"errors": {"name": "Ya existe un espacio deportivo con ese nombre en la '
      'sede seleccionada."}, "name": "Moron_Rivadavia_19850_Futbol_F5_2", '
      '"number": 2}';

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  Future<void> fill(WidgetTester tester) async {
    await choose(tester, 'Sede', 'Sede Morón');
    await choose(tester, 'Deporte', 'Fútbol');
    await choose(tester, 'Tipo', 'Fútbol 5');
    await choose(tester, 'Condición', 'Al aire libre');
    await choose(tester, 'Iluminación', 'Iluminada');
    await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
    await tester.tap(find.text('GUARDAR ESPACIO'));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      Future<void> open(
        WidgetTester tester,
        String start, [
        Map<String, (int, String)>? routes,
      ]) => mountAdmin(
        tester,
        dark: dark,
        size: size,
        start: start,
        api: apiRoutes(routes ?? spaceRoutes()),
      );

      if (width != '320') {
        testWidgets('spaces panel $width $mode', (tester) async {
          await open(tester, '/admin/spaces', {
            ...spaceRoutes(),
            'GET /spaces': (
              200,
              '{"spaces": [$spaceCastelarJson, $spaceF5Json, '
                  '$spaceTennisJson]}',
            ),
          });
          await capture(tester, 'admin/spaces_${width}_$mode.png');
        });
      }

      testWidgets('empty space creation $width $mode', (tester) async {
        await open(tester, '/admin/spaces/new');
        await capture(tester, 'admin/create_space_empty_${width}_$mode.png');
      });

      testWidgets('complete space creation $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester, '/admin/spaces/new');
        await fill(tester);
        await capture(tester, 'admin/create_space_complete_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('space creation with missing fields $width $mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await open(tester, '/admin/spaces/new');
        await choose(tester, 'Sede', 'Sede Morón');
        await choose(tester, 'Deporte', 'Fútbol');
        await save(tester);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 800),
        );
        await capture(tester, 'admin/create_space_missing_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('space creation with a duplicate $width $mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await open(
          tester,
          '/admin/spaces/new',
          spaceRoutes(create: (409, duplicate)),
        );
        await fill(tester);
        await save(tester);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 800),
        );
        await capture(
          tester,
          'admin/create_space_duplicate_${width}_$mode.png',
        );
        semantics.dispose();
      });

      testWidgets('space created $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester, '/admin/spaces/new');
        await fill(tester);
        await save(tester);
        await capture(tester, 'admin/space_created_${width}_$mode.png');
        semantics.dispose();
      });
    }
  }
}
