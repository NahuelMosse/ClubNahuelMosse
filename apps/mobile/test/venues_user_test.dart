import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';

void main() {
  setUpAll(loadFonts);

  test('the venue reads its sports, and without them it is empty', () {
    final withSports = Venue.fromJson({
      'id': '00000000-0000-7000-8000-000000000001',
      'name': 'Sede Morón',
      'address': 'Av. Rivadavia 19850',
      'opens_at': '08:00',
      'closes_at': '23:00',
      'open_days': [1, 2],
      'space_count': 2,
      'sports': ['Futbol', 'Tenis'],
    });
    expect(withSports?.sports, ['Futbol', 'Tenis']);
    final without = Venue.fromJson({
      'id': '00000000-0000-7000-8000-000000000001',
      'name': 'Sede Morón',
      'address': 'Av. Rivadavia 19850',
      'opens_at': '08:00',
      'closes_at': '23:00',
      'open_days': [1, 2],
      'space_count': 0,
    });
    expect(without?.sports, isEmpty);
  });

  group('all venues', () {
    testWidgets('each venue with hours, courts and sports', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountUser(tester, api: apiRoutes(venueRoutes()));
      expect(
        find.text('2 sedes · 2 canchas · cada una con su horario'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Sede Morón, Av. Rivadavia 19850, Lunes a domingo de 08:00 a 23:00, '
          '2 canchas: Fútbol, Tenis',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Sede Haedo, Av. Vergara 1850, Lunes a domingo de 08:00 a 22:00, '
          '0 canchas',
        ),
        findsOneWidget,
      );
      expect(find.text('SEDE MORÓN'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('says so when there are no venues', (tester) async {
      await mountUser(tester, api: apiRoutes(venueRoutes(venues: '[]')));
      expect(find.text('Todavía no hay sedes'), findsOneWidget);
      expect(find.text('El club todavía no cargó sus sedes.'), findsOneWidget);
    });

    testWidgets('if the server fails nothing is left in view', (tester) async {
      await mountUser(
        tester,
        api: apiRoutes({...venueRoutes(), 'GET /venues': (500, '{}')}),
      );
      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('Ver canchas'), findsNothing);
    });
  });

  group('one venue', () {
    testWidgets('shows the cover, the counter and each court', (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = <http.Request>[];
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: apiRoutes(venueRoutes(), requests: requests),
      );
      expect(find.text('SEDE MORÓN'), findsOneWidget);
      expect(find.text('AV. RIVADAVIA 19850 · 08:00 A 23:00'), findsOneWidget);
      expect(find.text('2 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Tenis, Moron_Rivadavia_19850_Tenis_PDL_1, Al aire libre, '
          'Sin iluminación, 32.000 pesos por hora',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Tenis · Polvo de ladrillo · Al aire libre · sin iluminación',
        ),
        findsOneWidget,
      );
      final courts = requests.where((p) => p.url.path == '/spaces').single;
      expect(courts.url.queryParameters, {
        'venue_id': '00000000-0000-7000-8000-000000000001',
      });
      semantics.dispose();
    });

    testWidgets('without courts it says so with the counter at zero', (
      tester,
    ) async {
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000005',
        api: apiRoutes(venueRoutes(spaces: '[]')),
      );
      expect(find.text('0 CANCHAS'), findsOneWidget);
      expect(find.text('Todavía no hay canchas'), findsOneWidget);
      expect(find.text('VER HORARIOS / RESERVAR'), findsNothing);
    });

    testWidgets(
      'a venue that is gone warns that it changed and returns to the listing',
      (tester) async {
        await mountUser(
          tester,
          start: '/venues/00000000-0000-7000-8000-000000000099',
          api: apiRoutes(venueRoutes()),
        );
        expect(find.text('Esto cambió mientras tanto'), findsOneWidget);
        await tester.tap(find.text('VER LO ACTUALIZADO'));
        await tester.pumpAndSettle();
        expect(find.text('Sedes'), findsOneWidget);
      },
    );

    testWidgets('«Todas las sedes» returns to the listing', (tester) async {
      await mountUser(tester, api: apiRoutes(venueRoutes(spaces: '[]')));
      await tester.tap(find.text('SEDE HAEDO'));
      await tester.pumpAndSettle();
      expect(find.text('0 CANCHAS'), findsOneWidget);
      await tester.tap(find.text('Todas las sedes'));
      await tester.pumpAndSettle();
      expect(find.text('0 CANCHAS'), findsNothing);
      expect(find.text('SEDE HAEDO'), findsOneWidget);
    });

    testWidgets('offline it warns and retries', (tester) async {
      var attempts = 0;
      final api = ApiClient(
        'http://api.falsa',
        client: _Client((request) async {
          final route = request.url.path;
          if (route == '/spaces' && attempts++ == 0) throw const _Outage();
          final (status, body) = venueRoutes()['GET $route'] ?? (404, '{}');
          return http.Response.bytes(utf8.encode(body), status);
        }),
      );
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: api,
      );
      expect(find.text('Error de conexión'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('REINTENTAR'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
    });
  });

  group('filter', () {
    const f7 =
        '{"id": "00000000-0000-7000-8000-000000000012", "name": "Moron_Rivadavia_19850_Futbol_F7_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
        '"venue": "Sede Morón", "sport": "Futbol", "kind": "F7", "number": 1, '
        '"covered": false, "lit": true, "price_per_hour": 55000}';

    /// An API that answers `GET /spaces` by the request's sport and kind.
    ApiClient api({List<http.Request>? requests, bool failsOnFilter = false}) =>
        ApiClient(
          'http://api.falsa',
          client: _Client((request) async {
            requests?.add(request as http.Request);
            final route = request.url.path;
            final q = request.url.queryParameters;
            if (route == '/spaces') {
              if (failsOnFilter && q.containsKey('sport')) {
                return http.Response('{}', 500);
              }
              final all = [spaceF5Json, f7, spaceTennisJson];
              final remaining = [
                for (final e in all)
                  if ((q['sport'] == null ||
                          e.contains('"sport": "${q['sport']}"')) &&
                      (q['kind'] == null ||
                          e.contains('"kind": "${q['kind']}"')))
                    e,
              ];
              return http.Response.bytes(
                utf8.encode('{"spaces": [${remaining.join(', ')}]}'),
                200,
              );
            }
            final (status, body) = venueRoutes()['GET $route'] ?? (404, '{}');
            return http.Response.bytes(utf8.encode(body), status);
          }),
        );

    Future<void> tapChip(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(label));
      await tester.pumpAndSettle();
    }

    testWidgets('sport, kind, «Todos» and removing the sport', (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = <http.Request>[];
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: api(requests: requests),
      );
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsNothing);

      await tapChip(tester, 'Deporte Fútbol');
      expect(find.text('2 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsOneWidget);
      expect(requests.last.url.queryParameters, {
        'venue_id': '00000000-0000-7000-8000-000000000001',
        'sport': 'Futbol',
      });

      await tapChip(tester, 'Tipo Fútbol 7');
      expect(find.text('1 CANCHA · FÚTBOL 7'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsNothing);

      await tapChip(tester, 'Tipo Todos');
      expect(find.text('2 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);

      await tapChip(tester, 'Deporte Fútbol');
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      semantics.dispose();
    });

    testWidgets('removing the sport asks again and brings the new data', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final data = [spaceF5Json, spaceTennisJson];
      final requests = <http.Request>[];
      final client = ApiClient(
        'http://api.falsa',
        client: _Client((request) async {
          requests.add(request as http.Request);
          final route = request.url.path;
          final q = request.url.queryParameters;
          if (route == '/spaces') {
            final remaining = [
              for (final e in data)
                if ((q['sport'] == null ||
                        e.contains('"sport": "${q['sport']}"')) &&
                    (q['kind'] == null || e.contains('"kind": "${q['kind']}"')))
                  e,
            ];
            return http.Response.bytes(
              utf8.encode('{"spaces": [${remaining.join(', ')}]}'),
              200,
            );
          }
          final (status, body) = venueRoutes()['GET $route'] ?? (404, '{}');
          return http.Response.bytes(utf8.encode(body), status);
        }),
      );
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: client,
      );
      await tapChip(tester, 'Deporte Fútbol');
      expect(find.text('1 CANCHA · FÚTBOL'), findsOneWidget);

      // Another admin adds a «Fútbol 7» in the meantime.
      data.add(f7);
      await tapChip(tester, 'Deporte Fútbol');
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(requests.last.url.queryParameters, {
        'venue_id': '00000000-0000-7000-8000-000000000001',
      });

      // Choosing the sport again shows the new kind.
      await tapChip(tester, 'Deporte Fútbol');
      expect(find.text('2 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);
      expect(find.bySemanticsLabel('Tipo Fútbol 7'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a sport with a single kind does not show the kind bar', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: api(),
      );
      await tapChip(tester, 'Deporte Tenis');
      expect(find.text('1 CANCHA · TENIS'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      semantics.dispose();
    });

    testWidgets('if filtering fails, it warns and stays as it was', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: api(failsOnFilter: true),
      );
      await tapChip(tester, 'Deporte Fútbol');
      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('schedule', () {
    testWidgets('arrives with the court chosen among those of its kind', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountUser(
        tester,
        start: '/venues/00000000-0000-7000-8000-000000000001',
        api: apiRoutes(venueRoutes()),
      );
      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Cancha 1, Al aire libre'))
            .flagsCollection
            .isSelected == Tristate.isTrue,
        isTrue,
      );
      // The tennis court is not of that kind.
      expect(find.textContaining('Tenis_PDL'), findsNothing);
      semantics.dispose();
    });
  });
}

class _Outage implements Exception {
  const _Outage();
}

class _Client extends http.BaseClient {
  _Client(this._respond);

  final Future<http.Response> Function(http.BaseRequest) _respond;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _respond(request);
    return http.StreamedResponse(
      Stream.value(r.bodyBytes),
      r.statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
