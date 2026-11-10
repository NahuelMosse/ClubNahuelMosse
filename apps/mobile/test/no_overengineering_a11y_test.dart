import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'kit/kit_a11y.dart';
import 'my_bookings_test.dart' show bookingJson;
import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('«Mis reservas» meets the accessibility guidelines @SIM-01-S1', (
    tester,
  ) async {
    final routes = venueRoutes();
    await mountUser(
      tester,
      start: '/reservas',
      api: ApiClient(
        'http://api.falsa',
        cliente: MockClient((request) async {
          final (code, body) = request.url.path == '/bookings'
              ? (
                  200,
                  '{"bookings": ${request.url.queryParameters['when'] == 'history' ? '[${bookingJson(id: '00000000-0000-7000-8000-000000000002', estado: 'canceled', motivo: 'Lluvia')}]' : '[${bookingJson()}]'}}',
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

    await kitA11y(tester);
  });

  testWidgets('«Inicio» meets the accessibility guidelines @SIM-01-S1', (
    tester,
  ) async {
    await mountScreen(
      tester,
      fakeHome(FakeSession(userProfile)),
      theme: darkTheme,
    );

    await kitA11y(tester);
  });

  testWidgets(
    'the admin\'s booking list meets the accessibility guidelines @SIM-01-S2',
    (tester) async {
      const booking =
          '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
          ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
          ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
          ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
          ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
          ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
          ' "canceled_by_name": null, "space_deactivated": false}';
      final api = apiRoutes({
        'GET /bookings/all': (
          200,
          '{"bookings": [$booking], "total": 1, "page": 1,'
              ' "per_page": 20, "counters": {"all": 1, "active": 1,'
              ' "completed": 0, "voided": 0}}',
        ),
        'GET /spaces/catalog': (200, catalogJson),
      });
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

      await kitA11y(tester);
    },
  );
}
