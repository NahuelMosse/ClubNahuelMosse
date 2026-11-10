import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  Future<void> fill(WidgetTester tester) async {
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
    FocusManager.instance.primaryFocus?.unfocus();
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      testWidgets('venues panel $width $mode', (tester) async {
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /venues': (
              200,
              '{"venues": [$venueCastelarJson, $venueHaedoJson, $venueMoronJson]}',
            ),
          }),
        );
        await capture(tester, 'admin/venues_${width}_$mode.png');
      });

      testWidgets('panel without venues $width $mode', (tester) async {
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await capture(tester, 'admin/venues_empty_${width}_$mode.png');
      });

      testWidgets('empty venue creation $width $mode', (tester) async {
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await capture(tester, 'admin/create_empty_${width}_$mode.png');
      });

      testWidgets('complete venue creation $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await fill(tester);
        await capture(tester, 'admin/create_complete_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('venue creation with missing fields $width $mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await tester.enterText(
          find.bySemanticsLabel('Nombre de la sede'),
          'Sede Haedo',
        );
        await choose(tester, 'Horario de apertura', '08:00');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.tap(find.text('GUARDAR SEDE'));
        await capture(tester, 'admin/create_missing_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('time picker $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await tester.tap(find.bySemanticsLabel('Horario de cierre'));
        await capture(tester, 'admin/selector_hour_${width}_$mode.png');
        semantics.dispose();
      });

      Future<void> openEdit(
        WidgetTester tester, {
        (int, String) onSave = (200, venueMoronJson),
      }) async {
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /venues': (200, '{"venues": [$venueMoronJson]}'),
            'PUT /venues/00000000-0000-7000-8000-000000000001': onSave,
          }),
        );
        await tester.tap(find.bySemanticsLabel('Editar sede Sede Morón'));
        await tester.pumpAndSettle();
      }

      testWidgets('edit venue $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await openEdit(tester);
        await capture(tester, 'admin/edit_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('edit venue with an empty field $width $mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await openEdit(tester);
        await tester.enterText(find.bySemanticsLabel('Dirección'), '');
        FocusManager.instance.primaryFocus?.unfocus();
        await capture(tester, 'admin/edit_empty_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('edit venue with bookings outside the hours $width $mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await openEdit(tester, onSave: (409, '{"bookings_outside": 3}'));
        await choose(tester, 'Horario de apertura', '10:00');
        await tester.tap(find.text('GUARDAR CAMBIOS'));
        await capture(tester, 'admin/edit_outside_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('confirm deactivating the venue $width $mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await openEdit(tester);
        await tester.tap(find.text('DAR DE BAJA LA SEDE'));
        await capture(tester, 'admin/deactivate_venue_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('venue with pending bookings $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          api: apiRoutes({
            'GET /venues': (200, '{"venues": [$venueMoronJson]}'),
            'DELETE /venues/00000000-0000-7000-8000-000000000001': (
              409,
              '{"errors": {"venue": "x"}}',
            ),
          }),
        );
        await tester.tap(find.bySemanticsLabel('Dar de baja Sede Morón'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('DAR DE BAJA'));
        await capture(
          tester,
          'admin/deactivate_with_bookings_${width}_$mode.png',
        );
        semantics.dispose();
      });

      testWidgets('edit space $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          start: '/admin/espacios',
          api: apiRoutes({
            'GET /spaces': (200, '{"spaces": [$spaceF5Json]}'),
            'GET /spaces/catalog': (200, catalogJson),
          }),
        );
        await tester.tap(
          find.bySemanticsLabel('Editar Moron_Rivadavia_19850_Futbol_F5_1'),
        );
        await tester.pumpAndSettle();
        await tester.enterText(find.bySemanticsLabel('Precio por hora'), '0');
        FocusManager.instance.primaryFocus?.unfocus();
        await capture(tester, 'admin/edit_space_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('venue created $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: dark,
          size: size,
          start: '/admin/sedes/nueva',
          api: apiRoutes({
            'POST /venues': (201, venueHaedoJson),
            'GET /venues': (200, '{"venues": [$venueHaedoJson]}'),
          }),
        );
        await fill(tester);
        await tester.tap(find.text('GUARDAR SEDE'));
        await capture(tester, 'admin/venue_created_${width}_$mode.png');
        semantics.dispose();
      });
    }
  }
}
