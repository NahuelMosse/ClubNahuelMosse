import 'package:clubnahuelmosse/common/clock.dart';
import 'package:clubnahuelmosse/features/bookings/domain/search_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';

void main() {
  final venue = Venue.fromJson({
    'id': '00000000-0000-7000-8000-000000000001',
    'name': 'Sede Morón',
    'address': 'Av. Rivadavia 19850',
    'opens_at': '08:00',
    'closes_at': '23:00',
    'open_days': [1, 2, 3, 4, 5, 6],
    'space_count': 2,
    'sports': ['Futbol'],
  })!;
  // Thursday, November 12, 2026, 18:20 at the club.
  final now = DateTime.utc(2026, 11, 12, 18, 20);
  final thursday = DateTime.utc(2026, 11, 12);

  Map<String, String> errors(DateTime day, int from, int to) =>
      rangeErrors(venue: venue, day: day, from: from, to: to, now: now);

  group('range rules', () {
    test('a future range of whole hours within opening hours passes', () {
      expect(errors(thursday, 19, 21), isEmpty);
      expect(errors(thursday.add(const Duration(days: 1)), 8, 12), isEmpty);
    });

    test(
      'the date must be from today to six days ahead and on an open day',
      () {
        expect(errors(thursday.subtract(const Duration(days: 1)), 19, 20), {
          'date': 'La fecha tiene que ser futura',
        });
        expect(errors(thursday.add(const Duration(days: 7)), 19, 20), {
          'date': 'Elegí un día de los próximos 7',
        });
        expect(errors(thursday.add(const Duration(days: 3)), 19, 20), {
          'date': 'La sede no abre ese día',
        });
      },
    );

    test('the duration is one to four hours and ends before closing', () {
      final friday = thursday.add(const Duration(days: 1));
      expect(
        errors(friday, 18, 18)['until'],
        'La duración mínima es de una hora',
      );
      expect(
        errors(friday, 10, 15)['until'],
        'La duración máxima es de 4 horas',
      );
      expect(errors(friday, 22, 0)['until'], 'La sede cierra a las 23:00');
      expect(errors(friday, 7, 9)['start_hour'], 'La sede abre a las 08:00');
    });

    test('today, a range that already started is not in the future', () {
      expect(errors(thursday, 18, 19), {
        'start_hour': 'El horario tiene que ser futuro',
      });
    });
  });

  group('screen', () {
    const available =
        '{"spaces": [$spaceF5Json, '
        '{"id": "00000000-0000-7000-8000-000000000011", "name": "Moron_Rivadavia_19850_Futbol_F5_2", "venue_id": "00000000-0000-7000-8000-000000000001", '
        '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 2, '
        '"covered": true, "lit": true, "price_per_hour": 43000}]}';

    Future<List<http.Request>> open(
      WidgetTester tester, {
      (int, String) response = (200, available),
      double scale = 1,
    }) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final requests = <http.Request>[];
      await mountUser(
        tester,
        start: '/home/search',
        size: scale > 1 ? const Size(360, 800) : const Size(393, 852),
        api: apiRoutes({
          ...venueRoutes(),
          'GET /spaces/available': response,
        }, requests: requests),
      );
      return requests;
    }

    Future<void> choose(
      WidgetTester tester,
      String field,
      String option,
    ) async {
      await tester.ensureVisible(find.bySemanticsLabel(field));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(field));
      await tester.pumpAndSettle();
      final button = find.descendant(
        of: find.byType(Dialog),
        matching: find.text(option),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    /// A day the venue opens within next week, as `DD / MM / AAAA`.
    String nextBusinessDay() {
      var d = clubNow().add(const Duration(days: 1));
      while (d.weekday == DateTime.sunday) {
        d = d.add(const Duration(days: 1));
      }
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)} / ${two(d.month)} / ${d.year}';
    }

    Future<void> fillIn(WidgetTester tester) async {
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await tester.enterText(
        find.descendant(
          of: find.bySemanticsLabel('Fecha'),
          matching: find.byType(EditableText),
        ),
        nextBusinessDay(),
      );
      await tester.pumpAndSettle();
    }

    bool isEnabled(WidgetTester tester, String label) => tester
        .getSemantics(find.bySemanticsLabel(label))
        .flagsCollection
        .isEnabled;

    testWidgets(
      'searching asks for venue, sport, date and range, and lists the free ones',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final requests = await open(tester);
        expect(isEnabled(tester, 'CONSULTAR'), isFalse);

        await fillIn(tester);
        await tester.tap(find.text('CONSULTAR'));
        await tester.pumpAndSettle();

        final query = requests.last.url;
        expect(query.path, '/spaces/available');
        expect(
          query.queryParameters['venue_id'],
          '00000000-0000-7000-8000-000000000001',
        );
        expect(query.queryParameters['sport'], 'Futbol');
        expect(query.queryParameters['since'], '18:00');
        expect(query.queryParameters['until'], '19:00');
        expect(query.queryParameters.containsKey('kind'), isFalse);
        expect(
          find.text('2 CANCHAS DISPONIBLES · FÚTBOL · 18:00 – 19:00'),
          findsOneWidget,
        );
        expect(find.textContaining('Sede Morón · Fútbol ·'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('the chips filter the result by condition', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.bySemanticsLabel('Techada (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Techada (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_2'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsNothing);
      semantics.dispose();
    });

    testWidgets('changing a filter clears the result', (tester) async {
      await open(tester);
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('CANCHAS DISPONIBLES'), findsOneWidget);

      await choose(tester, 'Hasta', '20:00');

      expect(find.textContaining('CANCHAS DISPONIBLES'), findsNothing);
    });

    testWidgets('an invalid range shows the error and does not search', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);
      await fillIn(tester);

      await choose(tester, 'Hasta', '18:00');

      expect(find.text('La duración mínima es de una hora'), findsOneWidget);
      expect(isEnabled(tester, 'CONSULTAR'), isFalse);
      expect(requests.where((p) => p.url.path == '/spaces/available'), isEmpty);
      semantics.dispose();
    });

    testWidgets('the server error offers to retry and leaves no results', (
      tester,
    ) async {
      await open(tester, response: (500, '{}'));
      await fillIn(tester);
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
      expect(find.text('No se pudo consultar la disponibilidad'), findsNothing);
    });

    testWidgets('the API rejects the range and the error goes on its field', (
      tester,
    ) async {
      await open(
        tester,
        response: (
          422,
          '{"errors": {"start_hour": "El horario tiene que ser futuro"}}',
        ),
      );
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      expect(find.text('El horario tiene que ser futuro'), findsOneWidget);
    });

    testWidgets('viewing times carries the day, the duration and the start', (
      tester,
    ) async {
      await open(tester);
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();

      expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
      expect(find.text('1 hora'), findsOneWidget);
    });

    testWidgets('with no results, the notice and «LIMPIAR FILTROS»', (
      tester,
    ) async {
      await open(tester, response: (200, '{"spaces": []}'));
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      expect(find.text('No hay canchas disponibles'), findsOneWidget);
      await tester.ensureVisible(find.text('LIMPIAR FILTROS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('LIMPIAR FILTROS'));
      await tester.pumpAndSettle();
      expect(find.text('Seleccioná una sede'), findsOneWidget);
    });

    testWidgets('with text at 200 % on a small phone nothing is clipped', (
      tester,
    ) async {
      await open(tester, scale: 2);
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping the date without changing it keeps the result', (
      tester,
    ) async {
      await open(tester);
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.bySemanticsLabel('Fecha'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Fecha'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CANCHAS DISPONIBLES'), findsOneWidget);
    });

    testWidgets('returning from the times leaves the search as it was', (
      tester,
    ) async {
      await open(tester);
      await fillIn(tester);
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

    testWidgets('the system back goes to the home', (tester) async {
      await open(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
    });

    testWidgets('a chip with no courts cannot be chosen', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester, response: (200, '{"spaces": [$spaceF5Json]}'));
      await fillIn(tester);
      await tester.tap(find.text('CONSULTAR'));
      await tester.pumpAndSettle();

      expect(isEnabled(tester, 'Techada (0)'), isFalse);
      semantics.dispose();
    });
  });
}
