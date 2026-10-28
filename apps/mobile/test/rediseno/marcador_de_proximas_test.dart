import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/common/marker.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_screen.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/bookings.dart';
import 'package:clubnahuelmosse/features/bookings/data/bookings_api.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

String _reserva(int id) {
  final desde = DateTime.utc(2026, 11, 12, 24).add(Duration(days: id));
  final hasta = desde.add(const Duration(hours: 1));
  return '{"id": "${_uuid(id)}", "espacio_id": "${_uuid(900)}", "sede_id": "${_uuid(200)}", '
      '"espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", '
      '"tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
      '"inicio": "${desde.toIso8601String()}", "fin": "${hasta.toIso8601String()}", '
      '"precio_por_hora": 38000, "total": 38000, "estado": "activa", '
      '"motivo": null, "cancelable": true}';
}

void main() {
  testWidgets(
    'inicio el marcador de próximas muestra la cantidad de reservas próximas @RED-03-ASM-13',
    (tester) async {
      final sesion = SesionFalsa(perfilUsuario);
      final api = apiRutas({
        'GET /reservas': (
          200,
          '{"reservas": [${[for (var i = 1; i <= 23; i++) _reserva(i)].join(', ')}]}',
        ),
        'GET /espacios/catalogo': (200, '{"deportes": []}'),
        'GET /sedes': (200, '{"sedes": []}'),
      });
      await montar(
        tester,
        HomeScreen(
          sesion: sesion,
          reservas: Bookings(BookingsApi(api: api, sesion: sesion)),
          espacios: Spaces(
            repository: SpacesRepository(api: api, session: sesion),
          ),
          sedes: Venues(
            repository: VenuesRepository(api: api, session: sesion),
          ),
        ),
        tema: darkTheme,
        tamano: const Size(393, 852),
      );

      expect(
        find.descendant(of: find.byType(AppMarker), matching: find.text('23')),
        findsOneWidget,
      );
    },
  );
}
