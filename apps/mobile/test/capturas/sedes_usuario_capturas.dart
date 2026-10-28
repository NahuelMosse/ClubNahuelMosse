import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../mis_reservas_test.dart' show reservaJson;
import '../soporte/admin.dart';
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};
  // La portada de cada sede sale de la suma de los caracteres de su id: el cuarto grupo
  // (8001) deja a Morón, Ramos Mejía y Haedo con las mismas portadas que tenían con ids numéricos.
  const sedeMoron = '00000000-0000-7000-8001-000000000001';
  const sedeRamos = '00000000-0000-7000-8001-000000000002';
  const sedeHaedo = '00000000-0000-7000-8001-000000000005';
  const idMoron = '00000000-0000-7000-8000-000000000001';
  const idHaedo = '00000000-0000-7000-8000-000000000005';
  final sedes =
      '[${sedeMoronConDeportes.replaceAll(idMoron, sedeMoron)}, '
      '{"id": "$sedeRamos", "nombre": "Sede Ramos Mejía", "direccion": "Calle Belgrano 1240", '
      '"apertura": "09:00", "cierre": "22:00", "dias": [1,2,3,4,5,6], '
      '"canchas": 2, "deportes": ["Hockey", "Voley"]}, '
      '${sedeHaedoSinCanchas.replaceAll(idHaedo, sedeHaedo)}]';
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
        String? espacios,
      }) => montarUsuario(
        tester,
        oscuro: oscuro,
        tamano: tamano,
        inicio: inicio,
        api: apiRutas({
          ...rutasDeSedes(
            sedes: sedes,
            espacios:
                espacios ??
                '[$espacioF5Json, $espacioTenisJson]'.replaceAll(
                  idMoron,
                  sedeMoron,
                ),
          ),
          'GET /espacios/catalogo': (200, catalogoCompleto),
          'POST /reservas': (
            201,
            reservaJson(
              inicio: '2026-11-12T21:00:00+00:00',
              fin: '2026-11-12T22:00:00+00:00',
            ),
          ),
        }),
      );

      testWidgets('todas las sedes $ancho $modo', (tester) async {
        await abrir(tester, '/sedes');
        await capturar(tester, 'sedes/todas_${ancho}_$modo.png');
      });

      testWidgets('sede con canchas $ancho $modo', (tester) async {
        await abrir(tester, '/sedes/$sedeMoron');
        await capturar(tester, 'sedes/sede_${ancho}_$modo.png');
      });

      testWidgets('sede filtrada por deporte $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester, '/sedes/$sedeMoron');
        await tester.tap(find.bySemanticsLabel('Deporte Fútbol'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sedes/sede_filtrada_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('sede sin canchas $ancho $modo', (tester) async {
        await abrir(tester, '/sedes/$sedeHaedo', espacios: '[]');
        await capturar(tester, 'sedes/sede_vacia_${ancho}_$modo.png');
      });

      testWidgets('horarios $ancho $modo', (tester) async {
        await abrir(
          tester,
          '/sedes/$sedeMoron/canchas/00000000-0000-7000-8000-000000000009',
        );
        await capturar(tester, 'sedes/horarios_${ancho}_$modo.png');
      });

      testWidgets('horarios con franja elegida $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(
          tester,
          '/sedes/$sedeMoron/canchas/00000000-0000-7000-8000-000000000009',
        );
        final franja = find.bySemanticsLabel('18:00 – 19:00');
        await tester.ensureVisible(franja);
        await tester.pumpAndSettle();
        await tester.tap(franja);
        await tester.pumpAndSettle();
        await capturar(tester, 'sedes/horarios_elegido_${ancho}_$modo.png');
        await tester.tap(find.text('CONTINUAR'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sedes/confirmar_${ancho}_$modo.png');
        await tester.tap(find.text('CONFIRMAR RESERVA'));
        await tester.pumpAndSettle();
        await capturar(tester, 'sedes/confirmada_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('horarios sin turnos $ancho $modo', (tester) async {
        await montarUsuario(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio:
              '/sedes/$sedeMoron/canchas/00000000-0000-7000-8000-000000000009',
          api: apiRutas({
            ...rutasDeSedes(sedes: sedes, grilla: grillaJson(abre: false)),
            'GET /espacios/catalogo': (200, catalogoCompleto),
          }),
        );
        await capturar(tester, 'sedes/horarios_vacio_${ancho}_$modo.png');
      });
    }
  }
}
