import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue_exceptions.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_texts.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/admin.dart';
import 'support/mount.dart';

void main() {
  group('days of the week', () {
    late AppLocalizations es;
    String text(List<int> days) => weekdaysText(es, weekdaysLabel(days));

    setUpAll(() async {
      es = await AppLocalizations.delegate.load(const Locale('es'));
    });

    test('runs of consecutive days from Monday are named', () {
      expect(text([7, 6, 5, 4, 3, 2, 1]), 'Lunes a domingo');
      expect(text([1, 2, 3, 4, 5, 6]), 'Lunes a sábado');
      expect(text([1, 2, 3, 4, 5]), 'Lunes a viernes');
    });

    test('loose days are abbreviated and in order', () {
      expect(text([5, 1, 3]), 'Lun, Mié, Vie');
      expect(text([6, 7]), 'Sáb, Dom');
    });
  });

  group('Venues', () {
    Venues venues(ApiClient api) => Venues(
      repository: VenuesRepository(
        api: api,
        session: FakeSession(adminProfile),
      ),
    );

    test('reads the active venues', () async {
      final api = apiRoutes({
        'GET /venues': (200, '{"venues": [$venueMoronJson, $venueHaedoJson]}'),
      });
      final read = await venues(api).repository.active();
      expect([for (final s in read) s.name], ['Sede Morón', 'Sede Haedo']);
      expect(
        weekdaysText(
          await AppLocalizations.delegate.load(const Locale('es')),
          read.first.daysLabel,
        ),
        'Lunes a sábado',
      );
      expect(read.first.spaceCount, 1);
    });

    test('a response that cannot be understood is a server error', () {
      final api = apiRoutes({
        'GET /venues': (
          200,
          '{"venues": [{"id": "00000000-0000-7000-8000-000000000001"}]}',
        ),
      });
      expect(venues(api).repository.active(), throwsA(isA<ServerError>()));
    });

    test('create sends the data and returns the saved venue', () async {
      final requests = <http.Request>[];
      final api = apiRoutes({
        'POST /venues': (201, venueHaedoJson),
      }, requests: requests);
      final venue = await venues(api).create(
        name: 'Sede Haedo',
        address: 'Av. Vergara 1850',
        opening: '08:00',
        closing: '23:00',
        days: const [1, 2, 3, 4, 5, 6, 7],
      );
      expect(venue.id, '00000000-0000-7000-8000-000000000005');
      expect(requests.single.headers['authorization'], 'Bearer token-falso');
      expect(jsonDecode(requests.single.body), {
        'name': 'Sede Haedo',
        'address': 'Av. Vergara 1850',
        'opens_at': '08:00',
        'closes_at': '23:00',
        'open_days': [1, 2, 3, 4, 5, 6, 7],
      });
    });

    Future<Venue> create(ApiClient api) => venues(api).create(
      name: 'Sede Haedo',
      address: 'Av. Vergara 1850',
      opening: '08:00',
      closing: '23:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
    );

    test('a repeated name comes back with the field message', () {
      final api = apiRoutes({
        'POST /venues': (
          409,
          '{"errors": {"name": "Ya existe una sede con ese nombre"}}',
        ),
      });
      expect(
        create(api),
        throwsA(
          isA<VenueRejected>().having((e) => e.errors, 'errors', {
            'name': 'Ya existe una sede con ese nombre',
          }),
        ),
      );
    });

    test('without a valid session it warns that it expired', () {
      final api = apiRoutes({'POST /venues': (401, '{}')});
      expect(create(api), throwsA(isA<SessionExpired>()));
    });

    test('a 403 is not a create: it is an error', () {
      final api = apiRoutes({'POST /venues': (403, '')});
      expect(create(api), throwsA(isA<ServerError>()));
    });
  });

  group('venues panel', () {
    testWidgets(
      'says so when there are no venues and lets the user add the first',
      (tester) async {
        await mountAdmin(
          tester,
          api: apiRoutes({'GET /venues': (200, '{"venues": []}')}),
        );
        expect(find.text('0 SEDES ACTIVAS'), findsOneWidget);
        expect(find.text('Todavía no hay sedes'), findsOneWidget);
        expect(find.text('AGREGAR SEDE'), findsOneWidget);
      },
    );

    testWidgets('each venue with its courts, days and hours', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        api: apiRoutes({
          'GET /venues': (
            200,
            '{"venues": [$venueMoronJson, $venueHaedoJson]}',
          ),
        }),
      );
      expect(find.text('2 SEDES ACTIVAS'), findsOneWidget);
      expect(find.text('Lunes a sábado · 09:00 a 00:00'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Sede Morón, Av. Rivadavia 19850, 1 cancha, '
          'Lunes a sábado de 09:00 a 00:00',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('offline it warns and lets the user retry', (tester) async {
      var attempts = 0;
      final api = ApiClient(
        'http://api.falsa',
        client: _Client((_) async {
          attempts++;
          if (attempts == 1) throw const _Outage();
          return http.Response('{"venues": []}', 200);
        }),
      );
      await mountAdmin(tester, api: api);
      expect(find.text('Error de conexión'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('REINTENTAR'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 SEDES ACTIVAS'), findsOneWidget);
    });
  });

  group('venue creation', () {
    Future<List<http.Request>> openCreate(
      WidgetTester tester, {
      (int, String) response = (201, venueHaedoJson),
    }) async {
      final requests = <http.Request>[];
      await mountAdmin(
        tester,
        start: '/admin/venues/new',
        api: apiRoutes({
          'POST /venues': response,
          'GET /venues': (200, '{"venues": [$venueHaedoJson]}'),
        }, requests: requests),
      );
      return requests;
    }

    Future<void> fillIn(WidgetTester tester) async {
      await tester.enterText(
        find.bySemanticsLabel('Nombre de la sede'),
        'Sede Haedo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Dirección'),
        'Av. Vergara 1850',
      );
      await choose(tester, 'Horario de apertura', '08:00');
      await choose(tester, 'Horario de cierre', '23:00');
    }

    testWidgets(
      'saving with nothing marks everything missing and does not send',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final requests = await openCreate(tester);
        await tester.tap(find.text('GUARDAR SEDE'));
        await tester.pumpAndSettle();
        expect(find.text('El nombre es obligatorio'), findsOneWidget);
        expect(find.text('La dirección es obligatoria'), findsOneWidget);
        expect(
          find.text('El horario de apertura es obligatorio'),
          findsOneWidget,
        );
        expect(
          find.text('El horario de cierre es obligatorio'),
          findsOneWidget,
        );
        expect(requests.where((p) => p.method == 'POST'), isEmpty);
        semantics.dispose();
      },
    );

    testWidgets('a field left empty is not marked until trying to save', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openCreate(tester);
      await tester.tap(find.bySemanticsLabel('Dirección'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Nombre de la sede'));
      await tester.pumpAndSettle();
      expect(find.text('La dirección es obligatoria'), findsNothing);
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('La dirección es obligatoria'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a half-written address is marked when leaving it', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openCreate(tester);
      await tester.enterText(find.bySemanticsLabel('Dirección'), 'Av. Vergara');
      await tester.tap(find.bySemanticsLabel('Nombre de la sede'));
      await tester.pumpAndSettle();
      expect(find.text('Escribí la calle y la altura'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('the address needs the street number', (tester) async {
      final semantics = tester.ensureSemantics();
      await openCreate(tester);
      await fillIn(tester);
      await tester.enterText(find.bySemanticsLabel('Dirección'), 'Av. Vergara');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('Escribí la calle y la altura'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('closing goes after opening, except midnight', (tester) async {
      final semantics = tester.ensureSemantics();
      await openCreate(tester);
      await choose(tester, 'Horario de apertura', '18:00');
      await choose(tester, 'Horario de cierre', '10:00');
      expect(
        find.text('El cierre tiene que ser después de la apertura'),
        findsOneWidget,
      );
      await choose(tester, 'Horario de cierre', '00:00');
      expect(
        find.text('El cierre tiene que ser después de la apertura'),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('saves with the chosen days and shows the created venue', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final requests = await openCreate(tester);
      await fillIn(tester);
      await choose(tester, 'Días que abre', 'Lunes a viernes');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      final createRequest = requests.singleWhere((p) => p.method == 'POST');
      expect(jsonDecode(createRequest.body), {
        'name': 'Sede Haedo',
        'address': 'Av. Vergara 1850',
        'opens_at': '08:00',
        'closes_at': '23:00',
        'open_days': [1, 2, 3, 4, 5],
      });
      expect(find.text('¡Sede creada!'), findsOneWidget);
      expect(find.text('Sede Haedo · Av. Vergara 1850'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a repeated name is marked on the field until it is changed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openCreate(
        tester,
        response: (
          409,
          '{"errors": {"name": "Ya existe una sede con ese nombre"}}',
        ),
      );
      await fillIn(tester);
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una sede con ese nombre'), findsOneWidget);
      await tester.enterText(
        find.bySemanticsLabel('Nombre de la sede'),
        'Sede Haedo Norte',
      );
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una sede con ese nombre'), findsNothing);
      semantics.dispose();
    });

    testWidgets('success without the saved venue leads to the listing', (
      tester,
    ) async {
      await mountAdmin(
        tester,
        start: '/admin/venues/created',
        api: apiRoutes({'GET /venues': (200, '{"venues": [$venueHaedoJson]}')}),
      );
      expect(find.text('¡Sede creada!'), findsNothing);
      expect(find.text('1 SEDE ACTIVA'), findsOneWidget);
    });
  });

  group('creation and listing together', () {
    Future<void> fillInAndSave(WidgetTester tester) async {
      await tester.tap(find.text('AGREGAR SEDE'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsLabel('Nombre de la sede'),
        'Sede Haedo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Dirección'),
        'Av. Vergara 1850',
      );
      await choose(tester, 'Horario de apertura', '08:00');
      await choose(tester, 'Horario de cierre', '23:00');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'on return from creation, the listing already shows the new venue',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var saved = false;
        final api = ApiClient(
          'http://api.falsa',
          client: _Client((request) async {
            if (request.method == 'POST') {
              saved = true;
              return http.Response(venueHaedoJson, 201);
            }
            return http.Response(
              saved ? '{"venues": [$venueHaedoJson]}' : '{"venues": []}',
              200,
            );
          }),
        );
        await mountAdmin(tester, api: api);
        expect(find.text('0 SEDES ACTIVAS'), findsOneWidget);
        await fillInAndSave(tester);
        expect(find.text('¡Sede creada!'), findsOneWidget);
        await tester.tap(find.text('IR AL LISTADO'));
        await tester.pumpAndSettle();
        expect(find.text('1 SEDE ACTIVA'), findsOneWidget);
        expect(find.text('Sede Haedo'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'if the listing below does not load, it does not cover the success',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var reads = 0;
        final api = ApiClient(
          'http://api.falsa',
          client: _Client((request) async {
            if (request.method == 'POST')
              return http.Response(venueHaedoJson, 201);
            reads++;
            if (reads > 1) throw const _Outage();
            return http.Response('{"venues": []}', 200);
          }),
        );
        await mountAdmin(tester, api: api);
        await fillInAndSave(tester);
        expect(find.text('¡Sede creada!'), findsOneWidget);
        expect(find.text('Error de conexión'), findsNothing);
        semantics.dispose();
      },
    );

    testWidgets(
      'if the create was saved but the response never arrived, the retry shows the success',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var creates = 0;
        final api = ApiClient(
          'http://api.falsa',
          client: _Client((request) async {
            if (request.method == 'POST') {
              creates++;
              if (creates == 1) throw const _Outage();
              return http.Response(
                '{"errors": {"name": "Ya existe una sede con ese nombre"}}',
                409,
              );
            }
            return http.Response(
              creates == 0 ? '{"venues": []}' : '{"venues": [$venueHaedoJson]}',
              200,
            );
          }),
        );
        await mountAdmin(tester, api: api);
        await fillInAndSave(tester);
        expect(find.text('Error de conexión'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(Dialog),
            matching: find.text('REINTENTAR'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('¡Sede creada!'), findsOneWidget);
        expect(find.text('Ya existe una sede con ese nombre'), findsNothing);
        semantics.dispose();
      },
    );
  });

  testWidgets('a user cannot enter the venues panel', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: apiRoutes({}),
        session: FakeSession(userProfile),
        appearance: Appearance.inMemory(),
        initialLocation: '/admin/venues/new',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nueva sede'), findsNothing);
    expect(find.text('Acceso denegado'), findsOneWidget);
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
      Stream.value(utf8.encode(r.body)),
      r.statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
