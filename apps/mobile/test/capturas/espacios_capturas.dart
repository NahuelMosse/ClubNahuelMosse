import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {
    '320': Size(320, 568),
    '360': Size(360, 800),
    '430': Size(430, 932),
  };
  const modos = {'oscuro': true, 'claro': false};
  const duplicado =
      '{"errors": {"name": "Ya existe un espacio deportivo con ese nombre en la '
      'sede seleccionada."}, "name": "Moron_Rivadavia_19850_Futbol_F5_2", '
      '"number": 2}';

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  Future<void> completar(WidgetTester tester) async {
    await elegir(tester, 'Sede', 'Sede Morón');
    await elegir(tester, 'Deporte', 'Fútbol');
    await elegir(tester, 'Tipo', 'Fútbol 5');
    await elegir(tester, 'Condición', 'Al aire libre');
    await elegir(tester, 'Iluminación', 'Iluminada');
    await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
    await tester.tap(find.text('GUARDAR ESPACIO'));
    await tester.pumpAndSettle();
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      Future<void> abrir(
        WidgetTester tester,
        String inicio, [
        Map<String, (int, String)>? rutas,
      ]) => montarAdmin(
        tester,
        oscuro: oscuro,
        tamano: tamano,
        inicio: inicio,
        api: apiRutas(rutas ?? rutasDeEspacios()),
      );

      if (ancho != '320') {
        testWidgets('panel de espacios $ancho $modo', (tester) async {
          await abrir(tester, '/admin/espacios', {
            ...rutasDeEspacios(),
            'GET /spaces': (
              200,
              '{"spaces": [$espacioCastelarJson, $espacioF5Json, '
                  '$espacioTenisJson]}',
            ),
          });
          await capturar(tester, 'admin/espacios_${ancho}_$modo.png');
        });
      }

      testWidgets('alta de espacio vacía $ancho $modo', (tester) async {
        await abrir(tester, '/admin/espacios/nuevo');
        await capturar(tester, 'admin/alta_espacio_vacia_${ancho}_$modo.png');
      });

      testWidgets('alta de espacio completa $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, '/admin/espacios/nuevo');
        await completar(tester);
        await capturar(
          tester,
          'admin/alta_espacio_completa_${ancho}_$modo.png',
        );
        semantica.dispose();
      });

      testWidgets('alta de espacio con faltantes $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, '/admin/espacios/nuevo');
        await elegir(tester, 'Sede', 'Sede Morón');
        await elegir(tester, 'Deporte', 'Fútbol');
        await guardar(tester);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 800),
        );
        await capturar(
          tester,
          'admin/alta_espacio_faltantes_${ancho}_$modo.png',
        );
        semantica.dispose();
      });

      testWidgets('alta de espacio duplicado $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(
          tester,
          '/admin/espacios/nuevo',
          rutasDeEspacios(alta: (409, duplicado)),
        );
        await completar(tester);
        await guardar(tester);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 800),
        );
        await capturar(
          tester,
          'admin/alta_espacio_duplicado_${ancho}_$modo.png',
        );
        semantica.dispose();
      });

      testWidgets('espacio creado $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, '/admin/espacios/nuevo');
        await completar(tester);
        await guardar(tester);
        await capturar(tester, 'admin/espacio_creado_${ancho}_$modo.png');
        semantica.dispose();
      });
    }
  }
}
