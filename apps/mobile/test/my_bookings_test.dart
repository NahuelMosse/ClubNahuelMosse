import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/my_bookings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/user.dart';

String bookingJson({
  String id = '00000000-0000-7000-8000-000000000001',
  String start = '2026-11-13T00:00:00+00:00',
  String end = '2026-11-13T01:00:00+00:00',
  String status = 'active',
  String? reason,
  bool? cancelable,
}) =>
    '{"id": "$id", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space": "Moron_Rivadavia_19850_Futbol_F5_1", '
    '"sport": "Futbol", "kind": "F5", "venue": "Sede Morón", '
    '"address": "Av. Rivadavia 19850", "starts_at": "$start", "ends_at": "$end", '
    '"price_per_hour": 38000, "total": 38000, "status": "$status", '
    '"reason": ${reason == null ? 'null' : '"$reason"'}, '
    '"cancelable": ${cancelable ?? status == 'active'}}';

void main() {
  const upcomingMalformed = '[{"id": "00000000-0000-7000-8000-000000000001"}]';

  Future<List<http.Request>> open(
    WidgetTester tester, {
    String upcoming = '[]',
    String history = '[]',
    int status = 200,
    Size size = const Size(393, 852),
  }) async {
    final requests = <http.Request>[];
    final routes = venueRoutes();
    await mountUser(
      tester,
      start: '/bookings',
      size: size,
      api: ApiClient(
        'http://api.falsa',
        client: MockClient((request) async {
          requests.add(request);
          final (code, body) = request.url.path == '/bookings'
              ? (
                  status,
                  '{"bookings": ${request.url.queryParameters['when'] == 'history' ? history : upcoming}}',
                )
              : routes['${request.method} ${request.url.path}'] ?? (404, '{}');
          return http.Response.bytes(
            utf8.encode(body),
            code,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    return requests;
  }

  testWidgets('the upcoming ones with their data and in the club\'s time', (
    tester,
  ) async {
    await open(tester, upcoming: '[${bookingJson()}]');

    expect(find.text('Fútbol 5'), findsOneWidget);
    expect(find.text('Sede Morón · Av. Rivadavia 19850'), findsOneWidget);
    expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
    // 00:00 UTC on the 13th is 21:00 on the 12th at the club.
    expect(find.text('Jue 12 de noviembre'), findsOneWidget);
    expect(find.text('21:00 – 22:00'), findsOneWidget);
    expect(find.text('ACTIVA'), findsOneWidget);
    expect(find.textContaining('38.000'), findsOneWidget);
  });

  testWidgets(
    'the history asks for its own list and says why it was canceled or voided',
    (tester) async {
      final requests = await open(
        tester,
        history:
            '[${bookingJson(status: 'canceled')}, '
            '${bookingJson(id: '00000000-0000-7000-8000-000000000002', status: 'voided', reason: 'lluvia')}, '
            '${bookingJson(id: '00000000-0000-7000-8000-000000000003', status: 'completed')}]',
      );

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(requests.last.url.queryParameters['when'], 'history');
      expect(find.text('CANCELADA'), findsOneWidget);
      expect(find.text('ANULADA'), findsOneWidget);
      expect(find.text('COMPLETADA'), findsOneWidget);
      expect(
        find.text('Cancelada por vos · el horario quedó liberado'),
        findsOneWidget,
      );
      expect(
        find.text('Anulada por el administrador · lluvia'),
        findsOneWidget,
      );
    },
  );

  testWidgets('with no bookings, the notice of each tab', (tester) async {
    await open(tester);
    expect(find.text('No hay próximas reservas'), findsOneWidget);

    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();
    expect(find.text('No hay reservas pasadas'), findsOneWidget);
  });

  testWidgets('a broken response leaves no half-loaded data', (tester) async {
    await open(tester, upcoming: upcomingMalformed);

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('REINTENTAR'), findsOneWidget);
  });

  testWidgets('with text at 200 % on a small phone nothing is cut off', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await open(
      tester,
      size: const Size(360, 800),
      upcoming: '[${bookingJson(status: 'active')}]',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a grouped notice tapped from Upcoming opens the history without a specific booking',
    (tester) async {
      final requests = await open(
        tester,
        upcoming: '[${bookingJson()}]',
        history:
            '[${bookingJson(id: '00000000-0000-7000-8000-000000000002', status: 'voided', reason: 'Lluvia')}]',
      );
      expect(find.text('ACTIVA'), findsOneWidget);

      GoRouter.of(
        tester.element(find.byType(MyBookingsScreen)),
      ).go('/bookings?history=1');
      await tester.pumpAndSettle();

      expect(requests.last.url.queryParameters['when'], 'history');
      expect(find.text('ANULADA'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNothing);
    },
  );
}
