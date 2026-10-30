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

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

String _reserva(int n) {
  final desde = DateTime.utc(2026, 11, 12, 21).add(Duration(days: n));
  final hasta = desde.add(const Duration(hours: 1));
  return '{"id": "${_uuid(n)}", "space_id": "${_uuid(9)}", "venue_id": "${_uuid(2)}", '
      '"space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", '
      '"kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850", '
      '"starts_at": "${desde.toIso8601String()}", "ends_at": "${hasta.toIso8601String()}", '
      '"price_per_hour": 38000, "total": 38000, "status": "active", '
      '"reason": null, "cancelable": true}';
}

void main() {
  testWidgets(
    'con veinte próximas el marcador dice 20 en su celda PRÓXIMAS, en el color del texto sobre foto @RED-03-ASM-13',
    (tester) async {
      final sesion = SesionFalsa(perfilUsuario);
      final api = apiRutas({
        'GET /bookings': (
          200,
          '{"bookings": [${[for (var i = 1; i <= 20; i++) _reserva(i)].join(', ')}]}',
        ),
        'GET /spaces/catalog': (200, '{"sports": []}'),
        'GET /venues': (200, '{"venues": []}'),
      });
      await montar(
        tester,
        HomeScreen(
          sesion: sesion,
          reservas: Bookings(BookingsApi(api: api, sesion: sesion)),
          espacios: Spaces(
            repository: SpacesRepository(api: api, session: sesion),
          ),
          venues: Venues(
            repository: VenuesRepository(api: api, session: sesion),
          ),
        ),
        tema: darkTheme,
        tamano: const Size(393, 852),
      );

      final cifra = find.descendant(
        of: find.byType(AppMarker),
        matching: find.text('20'),
      );
      expect(cifra, findsOneWidget);
      expect(find.text('20+'), findsNothing);
      expect(
        tester.widget<Text>(cifra).style?.color,
        Palette.dark.accentOnMedia,
      );
    },
  );
}
