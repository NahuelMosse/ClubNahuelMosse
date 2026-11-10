import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space_exceptions.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/price_format.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/space_texts.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/admin.dart';
import 'support/mount.dart';

void main() {
  group('price', () {
    test('is written in pesos with a thousands dot', () {
      expect(formatPesos(38000), '\$\u00A038.000');
      expect(formatPesos(1500000), '\$\u00A01.500.000');
    });

    test('the field keeps only digits and groups them', () {
      const formatter = PriceInputFormatter();
      TextEditingValue type(String text) => formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: text),
      );
      expect(type('38000').text, '\$\u00A038.000');
      expect(type('\$\u00A03a8.0 00').text, '\$\u00A038.000');
      expect(type('').text, '');
      expect(readPrice('\$\u00A038.000'), 38000);
      expect(readPrice('\$ '), isNull);
    });

    test('typing in the middle leaves the cursor where it was typed', () {
      const formatter = PriceInputFormatter();
      const before = TextEditingValue(
        text: '\$ 38.000',
        selection: TextSelection.collapsed(offset: 3),
      );
      // A 5 between the 3 and the 8.
      final after = formatter.formatEditUpdate(
        before,
        const TextEditingValue(
          text: '\$ 358.000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(after.text, '\$ 358.000');
      expect(after.selection.extentOffset, 4);
    });

    test('deleting over the thousands dot deletes the previous digit', () {
      const formatter = PriceInputFormatter();
      const before = TextEditingValue(
        text: '\$ 38.000',
        selection: TextSelection.collapsed(offset: 5),
      );
      final after = formatter.formatEditUpdate(
        before,
        const TextEditingValue(
          text: '\$ 38000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(after.text, '\$ 3.000');
    });

    test('pasted text with cents is cut at the comma', () {
      const formatter = PriceInputFormatter();
      final after = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1.500,00'),
      );
      expect(after.text, '\$ 1.500');
    });

    test('more than seven digits do not go in', () {
      const formatter = PriceInputFormatter();
      const before = TextEditingValue(text: '\$\u00A09.999.999');
      final after = formatter.formatEditUpdate(
        before,
        const TextEditingValue(text: '\$\u00A09.999.9990'),
      );
      expect(after.text, before.text);
    });
  });

  group('catalog', () {
    final catalog = Catalog.fromJson(jsonDecode(catalogJson));

    test('is read from the API', () {
      expect(catalog?.sports.map((d) => d.name), ['Fútbol', 'Tenis']);
    });

    test('the kind is named alone only if it already says the sport', () {
      expect(catalog?.readableKind('Futbol', 'F5'), 'Fútbol 5');
      expect(
        catalog?.readableKind('Tenis', 'PDL'),
        'Tenis · Polvo de ladrillo',
      );
    });

    test('the space description carries kind, condition and price', () {
      final space = Space.fromJson(jsonDecode(spaceTennisJson));
      final c = catalog;
      expect(space, isNotNull);
      expect(c, isNotNull);
      if (space == null || c == null) return;
      expect(
        spaceDescription(lookupAppLocalizations(const Locale('es')), space, c),
        'Tenis · Polvo de ladrillo · Al aire libre · \$\u00A032.000 por hora',
      );
    });
  });

  group('Spaces', () {
    Spaces spaces(ApiClient api) => Spaces(
      repository: SpacesRepository(
        api: api,
        session: FakeSession(adminProfile),
      ),
    );

    test('requests the catalog only once', () async {
      final requests = <http.Request>[];
      final e = spaces(apiRoutes(spaceRoutes(), requests: requests));
      await e.repository.catalog();
      await e.repository.catalog();
      expect(
        requests.where((p) => p.url.path == '/spaces/catalog'),
        hasLength(1),
      );
    });

    test(
      'the suggested name goes with the venue, the sport and the kind',
      () async {
        final requests = <http.Request>[];
        final e = spaces(apiRoutes(spaceRoutes(), requests: requests));
        final (name, number) = await e.suggestedName(
          venueId: '00000000-0000-7000-8000-000000000001',
          sport: 'Futbol',
          kind: 'F5',
        );
        expect((name, number), ('Moron_Rivadavia_19850_Futbol_F5_1', 1));
        expect(requests.single.url.queryParameters, {
          'venue_id': '00000000-0000-7000-8000-000000000001',
          'sport': 'Futbol',
          'kind': 'F5',
        });
      },
    );

    Future<Space> create(Spaces e) => e.create(
      venueId: '00000000-0000-7000-8000-000000000001',
      sport: 'Futbol',
      kind: 'F5',
      covered: false,
      lit: true,
      pricePerHour: 38000,
      number: 1,
    );

    test('the create call sends the number that was seen', () async {
      final requests = <http.Request>[];
      final e = spaces(apiRoutes(spaceRoutes(), requests: requests));
      final space = await create(e);
      expect(space.name, 'Moron_Rivadavia_19850_Futbol_F5_1');
      expect(jsonDecode(requests.single.body), {
        'venue_id': '00000000-0000-7000-8000-000000000001',
        'sport': 'Futbol',
        'kind': 'F5',
        'covered': false,
        'lit': true,
        'price_per_hour': 38000,
        'number': 1,
      });
    });

    test(
      'if another create took the number, it comes back with the next one',
      () {
        final e = spaces(
          apiRoutes(
            spaceRoutes(
              create: (
                409,
                '{"errors": {"name": "Ya existe"}, '
                    '"name": "Moron_Rivadavia_19850_Futbol_F5_2", "number": 2}',
              ),
            ),
          ),
        );
        expect(
          create(e),
          throwsA(
            isA<NameTaken>()
                .having(
                  (x) => x.name,
                  'name',
                  'Moron_Rivadavia_19850_Futbol_F5_2',
                )
                .having((x) => x.number, 'number', 2),
          ),
        );
      },
    );

    test('rejected data comes back per field', () {
      final e = spaces(
        apiRoutes(
          spaceRoutes(
            create: (
              422,
              '{"errors": {"venue_id": "La sede ya no está disponible"}}',
            ),
          ),
        ),
      );
      expect(create(e), throwsA(isA<SpaceRejected>()));
    });
  });

  group('spaces panel', () {
    testWidgets('counts the spaces and the venues', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountAdmin(
        tester,
        start: '/admin/espacios',
        api: apiRoutes({
          ...spaceRoutes(),
          'GET /spaces': (
            200,
            '{"spaces": [$spaceF5Json, $spaceTennisJson, $spaceCastelarJson]}',
          ),
        }),
      );
      expect(find.text('3 ESPACIOS ACTIVOS · 2 SEDES'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Tenis · Polvo de ladrillo · Al aire libre · \$\u00A032.000 por hora, '
          'Sede Morón, Moron_Rivadavia_19850_Tenis_PDL_1',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('says so when there are no spaces', (tester) async {
      await mountAdmin(
        tester,
        start: '/admin/espacios',
        api: apiRoutes({
          ...spaceRoutes(),
          'GET /spaces': (200, '{"spaces": []}'),
        }),
      );
      expect(find.text('0 ESPACIOS ACTIVOS · 0 SEDES'), findsOneWidget);
      expect(find.text('Todavía no hay espacios'), findsOneWidget);
    });
  });

  group('space creation', () {
    Future<List<http.Request>> open(
      WidgetTester tester, {
      Map<String, (int, String)>? routes,
    }) async {
      final requests = <http.Request>[];
      await mountAdmin(
        tester,
        start: '/admin/espacios/nuevo',
        api: apiRoutes(routes ?? spaceRoutes(), requests: requests),
      );
      return requests;
    }

    Future<void> fillIn(WidgetTester tester) async {
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await choose(tester, 'Tipo', 'Fútbol 5');
      await choose(tester, 'Condición', 'Al aire libre');
      await choose(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();
    }

    testWidgets('saving with nothing marks the six fields and does not send', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      expect(find.text('Este campo es obligatorio'), findsNWidgets(6));
      expect(requests.where((p) => p.method == 'POST'), isEmpty);
      semantics.dispose();
    });

    testWidgets(
      'the kind is chosen after the sport and changing the sport clears it',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester);
        await tester.tap(find.bySemanticsLabel('Tipo'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);

        await choose(tester, 'Deporte', 'Fútbol');
        await choose(tester, 'Tipo', 'Fútbol 7');
        expect(find.text('Fútbol 7'), findsOneWidget);
        await choose(tester, 'Deporte', 'Tenis');
        expect(find.text('Fútbol 7'), findsNothing);
        expect(find.text('Seleccioná el tipo'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets(
      'with venue, sport and kind it shows the name the API computes',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await open(tester);
        await choose(tester, 'Sede', 'Sede Morón');
        expect(find.text('Falta el deporte'), findsOneWidget);
        await choose(tester, 'Deporte', 'Fútbol');
        expect(find.text('Falta el tipo de cancha'), findsOneWidget);
        await choose(tester, 'Tipo', 'Fútbol 5');
        expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
        semantics.dispose();
      },
    );

    testWidgets('saves and shows the created space', (tester) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(tester);
      await fillIn(tester);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      final createRequest = requests.singleWhere((p) => p.method == 'POST');
      expect(jsonDecode(createRequest.body), containsPair('number', 1));
      expect(find.text('¡Espacio deportivo creado!'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('if the number is already taken, it warns and shows the next one', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(
        tester,
        routes: spaceRoutes(
          create: (
            409,
            '{"errors": {"name": "Ya existe un espacio deportivo con ese nombre '
                'en la sede seleccionada."}, '
                '"name": "Moron_Rivadavia_19850_Futbol_F5_2", "number": 2}',
          ),
        ),
      );
      await fillIn(tester);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Ya existe un espacio deportivo con ese nombre en la sede seleccionada.',
        ),
        findsOneWidget,
      );
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_2'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets(
      'if the name cannot be computed, it says so and lets the user retry',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final requests = await open(
          tester,
          routes: {...spaceRoutes(), 'GET /spaces/name': (500, '{}')},
        );
        await choose(tester, 'Sede', 'Sede Morón');
        await choose(tester, 'Deporte', 'Fútbol');
        await choose(tester, 'Tipo', 'Fútbol 5');
        expect(find.text('No se pudo calcular el nombre'), findsOneWidget);
        expect(find.text('Falta el tipo de cancha'), findsNothing);
        await tester.tap(find.text('REINTENTAR'));
        await tester.pumpAndSettle();
        expect(
          requests.where((p) => p.url.path == '/spaces/name'),
          hasLength(2),
        );
        semantics.dispose();
      },
    );

    testWidgets('saving without a computed name warns of the server error', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final requests = await open(
        tester,
        routes: {...spaceRoutes(), 'GET /spaces/name': (500, '{}')},
      );
      await fillIn(tester);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      expect(find.text('Error del servidor'), findsOneWidget);
      expect(requests.where((p) => p.method == 'POST'), isEmpty);
      semantics.dispose();
    });

    testWidgets('if the session expired while computing the name, it warns', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(
        tester,
        routes: {...spaceRoutes(), 'GET /spaces/name': (401, '{}')},
      );
      await choose(tester, 'Sede', 'Sede Morón');
      await choose(tester, 'Deporte', 'Fútbol');
      await choose(tester, 'Tipo', 'Fútbol 5');
      expect(find.text('Tu sesión expiró'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('without venues it says so and does not let the user choose', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester, routes: spaceRoutes(venues: '[]'));
      expect(find.text('Todavía no hay sedes'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Sede'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      semantics.dispose();
    });

    testWidgets('success without the saved space leads to the listing', (
      tester,
    ) async {
      await mountAdmin(
        tester,
        start: '/admin/espacios/creado',
        api: apiRoutes(spaceRoutes()),
      );
      expect(find.text('¡Espacio deportivo creado!'), findsNothing);
      expect(find.text('ALTA ESPACIO'), findsOneWidget);
    });
  });

  testWidgets('a user cannot enter space creation', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: apiRoutes({}),
        session: FakeSession(userProfile),
        appearance: Appearance.inMemory(),
        initialLocation: '/admin/espacios/nuevo',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nuevo espacio deportivo'), findsNothing);
    expect(find.text('Acceso denegado'), findsOneWidget);
  });
}
