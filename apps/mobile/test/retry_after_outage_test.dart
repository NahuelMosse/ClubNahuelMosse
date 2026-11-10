import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'void_booking_test.dart' as voidTest show listing, bookingJson;
import 'my_bookings_test.dart' show bookingJson;
import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// Answers [responses] in order to each POST to [route] (the last one repeats); a `null` is
/// a network outage. Anything that is not that POST is answered by [rest].
MockClient _withOutage(
  String route,
  List<(int, String)?> responses,
  (int, String) Function(http.Request) rest, {
  void Function()? onArrive,
}) {
  var n = 0;
  return MockClient((request) async {
    final (int, String) response;
    if (request.url.path == route && request.method == 'POST') {
      final next = responses[n < responses.length ? n : responses.length - 1];
      n++;
      // The server received the request even though the response did not come back.
      onArrive?.call();
      if (next == null) throw const SocketException('sin red');
      response = next;
    } else {
      response = rest(request);
    }
    return http.Response.bytes(
      utf8.encode(response.$2),
      response.$1,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  });
}

void main() {
  setUpAll(loadFonts);

  testWidgets('cancel: a 409 after an outage counts as canceled', (
    tester,
  ) async {
    final future = DateTime.now().toUtc().add(const Duration(days: 2));
    final start = DateTime.utc(future.year, future.month, future.day, 21);
    final upcoming = bookingJson(
      inicio: start.toIso8601String(),
      fin: start.add(const Duration(hours: 1)).toIso8601String(),
    );
    final routes = venueRoutes();
    var canceled = false;
    await mountUser(
      tester,
      start: '/reservas',
      api: ApiClient(
        'http://api.falsa',
        cliente: _withOutage(
          '/bookings/00000000-0000-7000-8000-000000000001/cancel',
          [
            null,
            (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}'),
          ],
          (request) {
            if (request.method == 'GET' && request.url.path == '/bookings') {
              return (200, '{"bookings": ${canceled ? '[]' : '[$upcoming]'}}');
            }
            return routes['${request.method} ${request.url.path}'] ??
                (404, '{}');
          },
          onArrive: () => canceled = true,
        ),
      ),
    );

    await tester.ensureVisible(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCELAR RESERVA'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva cancelada con éxito'), findsOneWidget);
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
  });

  testWidgets('void: a 409 after an outage counts as voided', (tester) async {
    final api = ApiClient(
      'http://api.falsa',
      cliente: _withOutage(
        '/bookings/00000000-0000-7000-8000-000000000001/void',
        [null, (409, '{"errors": {"reserva": "Esto cambió mientras tanto"}}')],
        (request) => switch (request.url.path) {
          '/bookings/all' => (200, voidTest.listing(voidTest.bookingJson())),
          '/spaces/catalog' => (200, catalogJson),
          _ => (404, '{}'),
        },
      ),
    );
    final session = FakeSession(adminProfile);
    await mountScreen(
      tester,
      AdminPanelScreen(
        history: BookingHistory(api: api, sesion: session),
        venues: Venues(
          repository: VenuesRepository(api: api, session: session),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        session: session,
        pending: PendingPanelFilters(),
      ),
      theme: darkTheme,
    );

    await tester.ensureVisible(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANULAR RESERVA'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Lluvia');
    await tester.ensureVisible(find.text('CONFIRMAR ANULACIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reserva anulada correctamente'), findsOneWidget);
    expect(find.text('Esto cambió mientras tanto'), findsNothing);
  });
}
