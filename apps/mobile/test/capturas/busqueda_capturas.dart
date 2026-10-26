import 'package:clubnahuelmosse/comun/reloj.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};
  const disponibles =
      '{"espacios": [$espacioF5Json, '
      '{"id": "00000000-0000-7000-8000-000000000011", "nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "sede_id": "00000000-0000-7000-8000-000000000001", '
      '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 2, '
      '"techada": true, "iluminada": true, "precio_por_hora": 43000}]}';

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.runAsync(() async {
      for (final elemento in find.byType(Image).evaluate()) {
        final imagen = elemento.widget;
        if (imagen is Image) await precacheImage(imagen.image, elemento);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  Future<void> elegir(WidgetTester tester, String campo, String opcion) async {
    await tester.ensureVisible(find.bySemanticsLabel(campo));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(campo));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text(opcion)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> completar(WidgetTester tester, {String hasta = '19:00'}) async {
    await elegir(tester, 'Sede', 'Sede Morón');
    await elegir(tester, 'Deporte', 'Fútbol');
    final d = ahoraEnElClub().add(const Duration(days: 1));
    String dos(int n) => n.toString().padLeft(2, '0');
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Fecha'),
        matching: find.byType(EditableText),
      ),
      '${dos(d.day)} / ${dos(d.month)} / ${d.year}',
    );
    await tester.pumpAndSettle();
    if (hasta != '19:00') await elegir(tester, 'Hasta', hasta);
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      Future<void> abrir(
        WidgetTester tester, {
        (int, String) respuesta = (200, disponibles),
      }) => montarUsuario(
        tester,
        oscuro: oscuro,
        tamano: tamano,
        inicio: '/inicio/buscar',
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /espacios/disponibles': respuesta,
        }),
      );

      testWidgets('inicio con accesos $ancho $modo', (tester) async {
        await montarUsuario(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/inicio',
          api: apiRutas({
            ...rutasDeSedes(),
            'GET /reservas': (200, '{"reservas": []}'),
            'GET /notificaciones': (
              200,
              '{"notificaciones": [], "no_leidas": 0}',
            ),
          }),
        );
        await capturar(tester, 'busqueda/inicio_${ancho}_$modo.png');
      });

      testWidgets('filtros $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester);
        await capturar(tester, 'busqueda/filtros_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('rango inválido $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester);
        await completar(tester, hasta: '18:00');
        await capturar(tester, 'busqueda/invalido_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('resultados $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester);
        await completar(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.textContaining('CANCHAS DISPONIBLES'));
        await capturar(tester, 'busqueda/resultados_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('sin resultados $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, respuesta: (200, '{"espacios": []}'));
        await completar(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('No hay canchas disponibles'));
        await capturar(tester, 'busqueda/vacio_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('error $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, respuesta: (500, '{}'));
        await completar(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.text('No se pudo consultar la disponibilidad'),
        );
        await capturar(tester, 'busqueda/error_${ancho}_$modo.png');
        semantica.dispose();
      });
    }
  }
}
