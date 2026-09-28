import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/usuario.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};
  const sedes =
      '[$sedeMoronConDeportes, '
      '{"id": 2, "nombre": "Sede Ramos Mejía", "direccion": "Calle Belgrano 1240", '
      '"apertura": "09:00", "cierre": "22:00", "dias": [1,2,3,4,5,6], '
      '"canchas": 2, "deportes": ["Hockey", "Voley"]}, '
      '$sedeHaedoSinCanchas]';
  const catalogoCompleto =
      '{"deportes": ['
      '{"clave": "Futbol", "nombre": "Fútbol", "tipos": ['
      '{"clave": "F5", "nombre": "Fútbol 5"}]},'
      '{"clave": "Tenis", "nombre": "Tenis", "tipos": ['
      '{"clave": "PDL", "nombre": "Polvo de ladrillo"}]},'
      '{"clave": "Voley", "nombre": "Vóley", "tipos": ['
      '{"clave": "IND", "nombre": "Indoor"}]},'
      '{"clave": "Hockey", "nombre": "Hockey", "tipos": ['
      '{"clave": "H7", "nombre": "Hockey 7"}]}]}';

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

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      Future<void> abrir(
        WidgetTester tester,
        String inicio, {
        String espacios = '[$espacioF5Json, $espacioTenisJson]',
      }) => montarUsuario(
        tester,
        oscuro: oscuro,
        tamano: tamano,
        inicio: inicio,
        api: apiRutas({
          ...rutasDeSedes(sedes: sedes, espacios: espacios),
          'GET /espacios/catalogo': (200, catalogoCompleto),
        }),
      );

      testWidgets('todas las sedes $ancho $modo', (tester) async {
        await abrir(tester, '/sedes');
        await capturar(tester, 'sedes/todas_${ancho}_$modo.png');
      });

      testWidgets('sede con canchas $ancho $modo', (tester) async {
        await abrir(tester, '/sedes/1');
        await capturar(tester, 'sedes/sede_${ancho}_$modo.png');
      });

      testWidgets('sede filtrada por deporte $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, '/sedes/1');
        await tester.tap(find.bySemanticsLabel('Deporte Fútbol'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sedes/sede_filtrada_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('sede sin canchas $ancho $modo', (tester) async {
        await abrir(tester, '/sedes/5', espacios: '[]');
        await capturar(tester, 'sedes/sede_vacia_${ancho}_$modo.png');
      });

      testWidgets('horarios $ancho $modo', (tester) async {
        await abrir(tester, '/sedes/1/canchas/9');
        await capturar(tester, 'sedes/horarios_${ancho}_$modo.png');
      });
    }
  }
}
