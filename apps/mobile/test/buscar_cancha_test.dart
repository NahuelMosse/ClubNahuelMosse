import 'package:clubnahuelmosse/comun/reloj.dart';
import 'package:clubnahuelmosse/reservas/reglas_busqueda.dart';
import 'package:clubnahuelmosse/sedes/sede.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  final sede = Sede.desdeJson({
    'id': 1,
    'nombre': 'Sede Morón',
    'direccion': 'Av. Rivadavia 19850',
    'apertura': '08:00',
    'cierre': '23:00',
    'dias': [1, 2, 3, 4, 5, 6],
    'canchas': 2,
    'deportes': ['Futbol'],
  })!;
  // Jueves 12 de noviembre de 2026, 18:20 en el club.
  final ahora = DateTime.utc(2026, 11, 12, 18, 20);
  final jueves = DateTime.utc(2026, 11, 12);

  Map<String, String> errores(DateTime dia, int desde, int hasta) =>
      erroresDelRango(
        sede: sede,
        dia: dia,
        desde: desde,
        hasta: hasta,
        ahora: ahora,
      );

  group('reglas del rango', () {
    test('un rango futuro, de horas completas y dentro del horario pasa', () {
      expect(errores(jueves, 19, 21), isEmpty);
      expect(errores(jueves.add(const Duration(days: 1)), 8, 12), isEmpty);
    });

    test('la fecha tiene que ser de hoy a seis días y de un día que abre', () {
      expect(errores(jueves.subtract(const Duration(days: 1)), 19, 20), {
        'fecha': 'La fecha tiene que ser futura',
      });
      expect(errores(jueves.add(const Duration(days: 7)), 19, 20), {
        'fecha': 'Elegí un día de los próximos 7',
      });
      expect(errores(jueves.add(const Duration(days: 3)), 19, 20), {
        'fecha': 'La sede no abre ese día',
      });
    });

    test('la duración va de una a cuatro horas y termina antes del cierre', () {
      final viernes = jueves.add(const Duration(days: 1));
      expect(
        errores(viernes, 18, 18)['hasta'],
        'La duración mínima es de una hora',
      );
      expect(
        errores(viernes, 10, 15)['hasta'],
        'La duración máxima es de 4 horas',
      );
      expect(errores(viernes, 22, 0)['hasta'], 'La sede cierra a las 23:00');
      expect(errores(viernes, 7, 9)['desde'], 'La sede abre a las 08:00');
    });

    test('hoy, un rango que ya empezó no es futuro', () {
      expect(errores(jueves, 18, 19), {
        'desde': 'El horario tiene que ser futuro',
      });
    });
  });

  group('pantalla', () {
    const disponibles =
        '{"espacios": [$espacioF5Json, '
        '{"id": 11, "nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "sede_id": 1, '
        '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F5", "numero": 2, '
        '"techada": true, "iluminada": true, "precio_por_hora": 43000}]}';

    Future<List<http.Request>> abrir(
      WidgetTester tester, {
      (int, String) respuesta = (200, disponibles),
      double escala = 1,
    }) async {
      tester.platformDispatcher.textScaleFactorTestValue = escala;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final pedidos = <http.Request>[];
      await montarUsuario(
        tester,
        inicio: '/inicio/buscar',
        tamano: escala > 1 ? const Size(360, 800) : const Size(393, 852),
        api: apiRutas({
          ...rutasDeSedes(),
          'GET /espacios/disponibles': respuesta,
        }, pedidos: pedidos),
      );
      return pedidos;
    }

    Future<void> elegir(
      WidgetTester tester,
      String campo,
      String opcion,
    ) async {
      await tester.ensureVisible(find.bySemanticsLabel(campo));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(campo));
      await tester.pumpAndSettle();
      final boton = find.descendant(
        of: find.byType(Dialog),
        matching: find.text(opcion),
      );
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();
    }

    /// Un día que la sede abre dentro de la semana que viene, en `DD / MM / AAAA`.
    String proximoDiaHabil() {
      var d = ahoraEnElClub().add(const Duration(days: 1));
      while (d.weekday == DateTime.sunday) {
        d = d.add(const Duration(days: 1));
      }
      String dos(int n) => n.toString().padLeft(2, '0');
      return '${dos(d.day)} / ${dos(d.month)} / ${d.year}';
    }

    Future<void> completar(WidgetTester tester) async {
      await elegir(tester, 'Sede', 'Sede Morón');
      await elegir(tester, 'Deporte', 'Fútbol');
      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Fecha'),
          matching: find.byType(EditableText),
        ),
        proximoDiaHabil(),
      );
      await tester.pumpAndSettle();
    }

    bool habilitado(WidgetTester tester, String etiqueta) => tester
        .getSemantics(find.bySemanticsLabel(etiqueta))
        .flagsCollection
        .isEnabled;

    testWidgets(
      'consultar pide sede, deporte, fecha y rango, y lista las libres',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final pedidos = await abrir(tester);
        expect(habilitado(tester, 'CONSULTAR'), isFalse);

        await completar(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();

        final consulta = pedidos.last.url;
        expect(consulta.path, '/espacios/disponibles');
        expect(consulta.queryParameters['sede_id'], '1');
        expect(consulta.queryParameters['deporte'], 'Futbol');
        expect(consulta.queryParameters['desde'], '18:00');
        expect(consulta.queryParameters['hasta'], '19:00');
        expect(consulta.queryParameters.containsKey('tipo'), isFalse);
        expect(
          find.text('2 CANCHAS DISPONIBLES · FÚTBOL · 18:00 – 19:00'),
          findsOneWidget,
        );
        expect(find.textContaining('Sede Morón · Fútbol ·'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets('los chips filtran el resultado por condición', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester);
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.bySemanticsLabel('Techada (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Techada (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_2'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsNothing);
      semantica.dispose();
    });

    testWidgets('cambiar un filtro quita el resultado', (tester) async {
      await abrir(tester);
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CANCHAS DISPONIBLES'), findsOneWidget);

      await elegir(tester, 'Hasta', '20:00');

      expect(find.textContaining('CANCHAS DISPONIBLES'), findsNothing);
    });

    testWidgets('un rango inválido muestra el error y no consulta', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);
      await completar(tester);

      await elegir(tester, 'Hasta', '18:00');

      expect(find.text('La duración mínima es de una hora'), findsOneWidget);
      expect(habilitado(tester, 'CONSULTAR'), isFalse);
      expect(
        pedidos.where((p) => p.url.path == '/espacios/disponibles'),
        isEmpty,
      );
      semantica.dispose();
    });

    testWidgets(
      'el error del servidor ofrece reintentar y no deja resultados',
      (tester) async {
        await abrir(tester, respuesta: (500, '{}'));
        await completar(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();

        expect(
          find.text('No se pudo consultar la disponibilidad'),
          findsOneWidget,
        );
        expect(find.textContaining('El servidor no respondió'), findsOneWidget);
        expect(find.textContaining('CANCHAS DISPONIBLES'), findsNothing);

        await tester.tap(find.text('VOLVER'));
        await tester.pumpAndSettle();
        expect(
          find.text('No se pudo consultar la disponibilidad'),
          findsNothing,
        );
      },
    );

    testWidgets('la API rechaza el rango y el error va en su campo', (
      tester,
    ) async {
      await abrir(
        tester,
        respuesta: (
          422,
          '{"errores": {"desde": "El horario tiene que ser futuro"}}',
        ),
      );
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      expect(find.text('El horario tiene que ser futuro'), findsOneWidget);
    });

    testWidgets('ver horarios lleva el día, la duración y el inicio', (
      tester,
    ) async {
      await abrir(tester);
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();

      expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
      expect(find.text('1 hora'), findsOneWidget);
    });

    testWidgets('sin resultados, el aviso y LIMPIAR FILTROS', (tester) async {
      await abrir(tester, respuesta: (200, '{"espacios": []}'));
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      expect(find.text('No hay canchas disponibles'), findsOneWidget);
      await tester.ensureVisible(find.text('LIMPIAR FILTROS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LIMPIAR FILTROS'));
      await tester.pumpAndSettle();
      expect(find.text('Seleccioná una sede'), findsOneWidget);
    });

    testWidgets('con el texto al 200 % en un teléfono chico no se corta nada', (
      tester,
    ) async {
      await abrir(tester, escala: 2);
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tocar la fecha sin cambiarla no quita el resultado', (
      tester,
    ) async {
      await abrir(tester);
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.bySemanticsLabel('Fecha'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Fecha'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CANCHAS DISPONIBLES'), findsOneWidget);
    });

    testWidgets('volver de los horarios deja la búsqueda como estaba', (
      tester,
    ) async {
      await abrir(tester);
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buscar cancha'));
      await tester.pumpAndSettle();

      expect(find.text('Consultar canchas'), findsOneWidget);
      expect(find.textContaining('CANCHAS DISPONIBLES'), findsOneWidget);
    });

    testWidgets('el atrás del sistema vuelve al inicio', (tester) async {
      await abrir(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
    });

    testWidgets('un chip sin canchas no se puede elegir', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester, respuesta: (200, '{"espacios": [$espacioF5Json]}'));
      await completar(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      expect(habilitado(tester, 'Techada (0)'), isFalse);
      semantica.dispose();
    });
  });
}
