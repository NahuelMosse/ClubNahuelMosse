import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/bookings.dart';
import 'package:clubnahuelmosse/features/bookings/data/bookings_api.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

String _booking(int n) {
  final start = DateTime.utc(2026, 11, 12, 21).add(Duration(days: n));
  final end = start.add(const Duration(hours: 1));
  return '{"id": "${_uuid(n)}", "space_id": "${_uuid(9)}", "venue_id": "${_uuid(2)}", '
      '"space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", '
      '"kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850", '
      '"starts_at": "${start.toIso8601String()}", "ends_at": "${end.toIso8601String()}", '
      '"price_per_hour": 38000, "total": 38000, "status": "active", '
      '"reason": null, "cancelable": true}';
}

void main() {
  testWidgets(
    'with twenty upcoming the marker says 20 in its «PRÓXIMAS» cell, in the on-photo text color @RED-03-ASM-13',
    (tester) async {
      final session = FakeSession(userProfile);
      final api = apiRoutes({
        'GET /bookings': (
          200,
          '{"bookings": [${[for (var i = 1; i <= 20; i++) _booking(i)].join(', ')}]}',
        ),
        'GET /spaces/catalog': (200, '{"sports": []}'),
        'GET /venues': (200, '{"venues": []}'),
      });
      await mountScreen(
        tester,
        HomeScreen(
          session: session,
          bookings: Bookings(BookingsApi(api: api, session: session)),
          spaces: Spaces(
            repository: SpacesRepository(api: api, session: session),
          ),
          venues: Venues(
            repository: VenuesRepository(api: api, session: session),
          ),
        ),
        theme: darkTheme,
        size: const Size(393, 852),
      );

      final figure = find.descendant(
        of: find.byType(AppMarker),
        matching: find.text('20'),
      );
      expect(figure, findsOneWidget);
      expect(find.text('20+'), findsNothing);
      expect(
        tester.widget<Text>(figure).style?.color,
        Palette.dark.accentOnMedia,
      );
    },
  );
}
