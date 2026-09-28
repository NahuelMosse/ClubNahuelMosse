import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/admin.dart';
import '../soporte/montar.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};

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
    await elegir(tester, 'Horario de apertura', '08:00');
    await elegir(tester, 'Horario de cierre', '23:00');
    FocusManager.instance.primaryFocus?.unfocus();
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      testWidgets('panel de sedes $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({
            'GET /sedes': (
              200,
              '{"sedes": [$sedeCastelarJson, $sedeHaedoJson, $sedeMoronJson]}',
            ),
          }),
        );
        await capturar(tester, 'admin/sedes_${ancho}_$modo.png');
      });

      testWidgets('panel sin sedes $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
        );
        await capturar(tester, 'admin/sedes_vacio_${ancho}_$modo.png');
      });

      testWidgets('alta de sede vacía $ancho $modo', (tester) async {
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
        );
        await capturar(tester, 'admin/alta_vacia_${ancho}_$modo.png');
      });

      testWidgets('alta de sede completa $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
        );
        await completar(tester);
        await capturar(tester, 'admin/alta_completa_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('alta de sede con faltantes $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
        );
        await tester.enterText(
          find.bySemanticsLabel('Nombre de la sede'),
          'Sede Haedo',
        );
        await elegir(tester, 'Horario de apertura', '08:00');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.tap(find.text('GUARDAR SEDE'));
        await capturar(tester, 'admin/alta_faltantes_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('selector de horario $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
        );
        await tester.tap(find.bySemanticsLabel('Horario de cierre'));
        await capturar(tester, 'admin/selector_hora_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('sede creada $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarAdmin(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({
            'POST /sedes': (201, sedeHaedoJson),
            'GET /sedes': (200, '{"sedes": [$sedeHaedoJson]}'),
          }),
        );
        await completar(tester);
        await tester.tap(find.text('GUARDAR SEDE'));
        await capturar(tester, 'admin/sede_creada_${ancho}_$modo.png');
        semantica.dispose();
      });
    }
  }
}
