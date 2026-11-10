import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'support/mount.dart';
import 'support/user.dart';

void main() {
  // Always in the future, so the card offers CANCELAR.
  final future = DateTime.now().toUtc().add(const Duration(days: 2));
  final start = DateTime.utc(future.year, future.month, future.day, 21);
  final upcoming = bookingJson(
    start: start.toIso8601String(),
    end: start.add(const Duration(hours: 1)).toIso8601String(),
  );

  Future<List<http.Request>> open(
    WidgetTester tester, {
    (int, String)? onCancel,
    String upcomingAfter = '[]',
  }) async {
    final requests = <http.Request>[];
    var canceled = false;
    final routes = venueRoutes();
    await mountUser(
      tester,
      start: '/reservas',
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          requests.add(request);
          final (status, body) = switch ((request.method, request.url.path)) {
            ('POST', '/bookings/00000000-0000-7000-8000-000000000001/cancel') =>
              () {
                final response =
                    onCancel ?? (200, bookingJson(status: 'canceled'));
                // A 409 also leaves the list without that booking: it was no longer active.
                canceled = response.$1 == 200 || response.$1 == 409;
                return response;
              }(),
            ('GET', '/bookings') => (
              200,
              '{"bookings": ${canceled ? upcomingAfter : '[$upcoming]'}}',
            ),
            _ => routes['${request.method} ${request.url.path}'] ?? (404, '{}'),
          };
          return http.Response.bytes(
            utf8.encode(body),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );
    return requests;
  }

  Future<void> askToCancel(WidgetTester tester) async {
    await tester.ensureVisible(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
  }

  testWidgets('confirming cancels, notifies and re-reads the list', (
    tester,
  ) async {
    final requests = await open(tester);

    await askToCancel(tester);
    expect(find.text('¿Cancelar la reserva?'), findsOneWidget);
    expect(find.textContaining('Fútbol 5 · Sede Morón ·'), findsOneWidget);
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();

    expect(requests.where((p) => p.method == 'POST'), hasLength(1));
    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('No hay próximas reservas'), findsOneWidget);
  });

  testWidgets('«NO CANCELAR» closes without sending anything', (tester) async {
    final requests = await open(tester);

    await askToCancel(tester);
    await tester.tap(find.text('NO CANCELAR'));
    await tester.pumpAndSettle();

    expect(requests.where((p) => p.method == 'POST'), isEmpty);
    expect(find.text('ACTIVA'), findsOneWidget);
  });

  testWidgets('if the booking changed, the notice and the updated list', (
    tester,
  ) async {
    await open(
      tester,
      onCancel: (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}'),
    );

    await askToCancel(tester);
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
    await tester.tap(find.text('VER LO ACTUALIZADO'));
    await tester.pumpAndSettle();
    expect(find.text('No hay próximas reservas'), findsOneWidget);
  });

  testWidgets('the server fails: the notice shows and the booking stays', (
    tester,
  ) async {
    await open(tester, onCancel: (500, '{}'));

    await askToCancel(tester);
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();

    expect(find.text('Error del servidor'), findsOneWidget);
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('ACTIVA'), findsOneWidget);
  });

  testWidgets(
    'a booking the server does not report as cancelable does not offer CANCELAR',
    (tester) async {
      final now = DateTime.now().toUtc();
      final started = bookingJson(
        start: now.subtract(const Duration(minutes: 10)).toIso8601String(),
        end: now.add(const Duration(minutes: 50)).toIso8601String(),
        cancelable: false,
      );
      await mountUser(
        tester,
        start: '/reservas',
        api: apiRoutes({
          ...venueRoutes(),
          'GET /bookings': (200, '{"bookings": [$started]}'),
        }),
      );

      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('CANCELAR'), findsNothing);
    },
  );
}
