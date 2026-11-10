import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/admin.dart';
import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(loadFonts);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'dark': true, 'light': false};

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  Future<void> completar(WidgetTester tester) async {
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

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      testWidgets('panel de sedes $ancho $modo', (tester) async {
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          api: apiRoutes({
            'GET /venues': (
              200,
              '{"venues": [$venueCastelarJson, $venueHaedoJson, $venueMoronJson]}',
            ),
          }),
        );
        await capturar(tester, 'admin/venues_${ancho}_$modo.png');
      });

      testWidgets('panel sin sedes $ancho $modo', (tester) async {
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await capturar(tester, 'admin/venues_empty_${ancho}_$modo.png');
      });

      testWidgets('alta de sede vacía $ancho $modo', (tester) async {
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await capturar(tester, 'admin/create_empty_${ancho}_$modo.png');
      });

      testWidgets('alta de sede completa $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await completar(tester);
        await capturar(tester, 'admin/create_complete_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('alta de sede con faltantes $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
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
        await capturar(tester, 'admin/create_missing_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('selector de horario $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          start: '/admin/sedes/nueva',
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        await tester.tap(find.bySemanticsLabel('Horario de cierre'));
        await capturar(tester, 'admin/selector_hour_${ancho}_$modo.png');
        semantica.dispose();
      });

      Future<void> abrirEdicion(
        WidgetTester tester, {
        (int, String) alGuardar = (200, venueMoronJson),
      }) async {
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          api: apiRoutes({
            'GET /venues': (200, '{"venues": [$venueMoronJson]}'),
            'PUT /venues/00000000-0000-7000-8000-000000000001': alGuardar,
          }),
        );
        await tester.tap(find.bySemanticsLabel('Editar sede Sede Morón'));
        await tester.pumpAndSettle();
      }

      testWidgets('editar sede $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrirEdicion(tester);
        await capturar(tester, 'admin/edit_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('editar sede con un campo vacío $ancho $modo', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await abrirEdicion(tester);
        await tester.enterText(find.bySemanticsLabel('Dirección'), '');
        FocusManager.instance.primaryFocus?.unfocus();
        await capturar(tester, 'admin/edit_empty_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('editar sede con reservas afuera $ancho $modo', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await abrirEdicion(tester, alGuardar: (409, '{"bookings_outside": 3}'));
        await choose(tester, 'Horario de apertura', '10:00');
        await tester.tap(find.text('GUARDAR CAMBIOS'));
        await capturar(tester, 'admin/edit_outside_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('confirmar la baja de la sede $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrirEdicion(tester);
        await tester.tap(find.text('DAR DE BAJA LA SEDE'));
        await capturar(tester, 'admin/deactivate_venue_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('sede con reservas pendientes $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
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
        await capturar(
          tester,
          'admin/deactivate_with_bookings_${ancho}_$modo.png',
        );
        semantica.dispose();
      });

      testWidgets('editar espacio $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
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
        await capturar(tester, 'admin/edit_space_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('sede creada $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await mountAdmin(
          tester,
          dark: oscuro,
          size: tamano,
          start: '/admin/sedes/nueva',
          api: apiRoutes({
            'POST /venues': (201, venueHaedoJson),
            'GET /venues': (200, '{"venues": [$venueHaedoJson]}'),
          }),
        );
        await completar(tester);
        await tester.tap(find.text('GUARDAR SEDE'));
        await capturar(tester, 'admin/venue_created_${ancho}_$modo.png');
        semantica.dispose();
      });
    }
  }
}
