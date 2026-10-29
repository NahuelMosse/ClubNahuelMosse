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

import 'soporte/admin.dart';
import 'soporte/montar.dart';

void main() {
  group('precio', () {
    test('se escribe en pesos con punto de miles', () {
      expect(formatPesos(38000), '\$\u00A038.000');
      expect(formatPesos(1500000), '\$\u00A01.500.000');
    });

    test('el campo deja sólo dígitos y los agrupa', () {
      const formato = PriceInputFormatter();
      TextEditingValue escribir(String texto) => formato.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: texto),
      );
      expect(escribir('38000').text, '\$\u00A038.000');
      expect(escribir('\$\u00A03a8.0 00').text, '\$\u00A038.000');
      expect(escribir('').text, '');
      expect(readPrice('\$\u00A038.000'), 38000);
      expect(readPrice('\$ '), isNull);
    });

    test('escribir en el medio deja el cursor donde se escribió', () {
      const formato = PriceInputFormatter();
      const antes = TextEditingValue(
        text: '\$ 38.000',
        selection: TextSelection.collapsed(offset: 3),
      );
      // Un 5 entre el 3 y el 8.
      final despues = formato.formatEditUpdate(
        antes,
        const TextEditingValue(
          text: '\$ 358.000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(despues.text, '\$ 358.000');
      expect(despues.selection.extentOffset, 4);
    });

    test('borrar sobre el punto de miles borra el dígito anterior', () {
      const formato = PriceInputFormatter();
      const antes = TextEditingValue(
        text: '\$ 38.000',
        selection: TextSelection.collapsed(offset: 5),
      );
      final despues = formato.formatEditUpdate(
        antes,
        const TextEditingValue(
          text: '\$ 38000',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(despues.text, '\$ 3.000');
    });

    test('lo pegado con centavos se corta en la coma', () {
      const formato = PriceInputFormatter();
      final despues = formato.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '1.500,00'),
      );
      expect(despues.text, '\$ 1.500');
    });

    test('más de siete dígitos no entra', () {
      const formato = PriceInputFormatter();
      const antes = TextEditingValue(text: '\$\u00A09.999.999');
      final despues = formato.formatEditUpdate(
        antes,
        const TextEditingValue(text: '\$\u00A09.999.9990'),
      );
      expect(despues.text, antes.text);
    });
  });

  group('catálogo', () {
    final catalogo = Catalog.fromJson(jsonDecode(catalogoJson));

    test('se lee de la API', () {
      expect(catalogo?.sports.map((d) => d.name), ['Fútbol', 'Tenis']);
    });

    test('el tipo se nombra solo si ya dice el deporte', () {
      expect(catalogo?.readableKind('Futbol', 'F5'), 'Fútbol 5');
      expect(
        catalogo?.readableKind('Tenis', 'PDL'),
        'Tenis · Polvo de ladrillo',
      );
    });

    test('la descripción del espacio lleva tipo, condición y precio', () {
      final espacio = Space.fromJson(jsonDecode(espacioTenisJson));
      final c = catalogo;
      expect(espacio, isNotNull);
      expect(c, isNotNull);
      if (espacio == null || c == null) return;
      expect(
        spaceDescription(
          lookupAppLocalizations(const Locale('es')),
          espacio,
          c,
        ),
        'Tenis · Polvo de ladrillo · Al aire libre · \$\u00A032.000 por hora',
      );
    });
  });

  group('Espacios', () {
    Spaces espacios(ApiClient api) => Spaces(
      repository: SpacesRepository(api: api, session: SesionFalsa(perfilAdmin)),
    );

    test('pide el catálogo una sola vez', () async {
      final pedidos = <http.Request>[];
      final e = espacios(apiRutas(rutasDeEspacios(), pedidos: pedidos));
      await e.repository.catalog();
      await e.repository.catalog();
      expect(
        pedidos.where((p) => p.url.path == '/espacios/catalogo'),
        hasLength(1),
      );
    });

    test('el nombre sugerido va con la sede, el deporte y el tipo', () async {
      final pedidos = <http.Request>[];
      final e = espacios(apiRutas(rutasDeEspacios(), pedidos: pedidos));
      final (nombre, numero) = await e.suggestedName(
        venueId: '00000000-0000-7000-8000-000000000001',
        sport: 'Futbol',
        kind: 'F5',
      );
      expect((nombre, numero), ('Moron_Rivadavia_19850_Futbol_F5_1', 1));
      expect(pedidos.single.url.queryParameters, {
        'sede_id': '00000000-0000-7000-8000-000000000001',
        'deporte': 'Futbol',
        'tipo': 'F5',
      });
    });

    Future<Space> alta(Spaces e) => e.create(
      venueId: '00000000-0000-7000-8000-000000000001',
      sport: 'Futbol',
      kind: 'F5',
      covered: false,
      lit: true,
      pricePerHour: 38000,
      number: 1,
    );

    test('el alta manda el número que se vio', () async {
      final pedidos = <http.Request>[];
      final e = espacios(apiRutas(rutasDeEspacios(), pedidos: pedidos));
      final espacio = await alta(e);
      expect(espacio.name, 'Moron_Rivadavia_19850_Futbol_F5_1');
      expect(jsonDecode(pedidos.single.body), {
        'sede_id': '00000000-0000-7000-8000-000000000001',
        'deporte': 'Futbol',
        'tipo': 'F5',
        'techada': false,
        'iluminada': true,
        'precio_por_hora': 38000,
        'numero': 1,
      });
    });

    test('si otro alta tomó el número, vuelve con el siguiente', () {
      final e = espacios(
        apiRutas(
          rutasDeEspacios(
            alta: (
              409,
              '{"errores": {"nombre": "Ya existe"}, '
                  '"nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "numero": 2}',
            ),
          ),
        ),
      );
      expect(
        alta(e),
        throwsA(
          isA<NameTaken>()
              .having(
                (x) => x.name,
                'nombre',
                'Moron_Rivadavia_19850_Futbol_F5_2',
              )
              .having((x) => x.number, 'numero', 2),
        ),
      );
    });

    test('los datos rechazados vuelven por campo', () {
      final e = espacios(
        apiRutas(
          rutasDeEspacios(
            alta: (
              422,
              '{"errores": {"sede_id": "La sede ya no está disponible"}}',
            ),
          ),
        ),
      );
      expect(alta(e), throwsA(isA<SpaceRejected>()));
    });
  });

  group('panel de espacios', () {
    testWidgets('cuenta los espacios y las sedes', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        inicio: '/admin/espacios',
        api: apiRutas({
          ...rutasDeEspacios(),
          'GET /espacios': (
            200,
            '{"espacios": [$espacioF5Json, $espacioTenisJson, $espacioCastelarJson]}',
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
      semantica.dispose();
    });

    testWidgets('sin espacios lo dice', (tester) async {
      await montarAdmin(
        tester,
        inicio: '/admin/espacios',
        api: apiRutas({
          ...rutasDeEspacios(),
          'GET /espacios': (200, '{"espacios": []}'),
        }),
      );
      expect(find.text('0 ESPACIOS ACTIVOS · 0 SEDES'), findsOneWidget);
      expect(find.text('Todavía no hay espacios'), findsOneWidget);
    });
  });

  group('alta de espacio', () {
    Future<List<http.Request>> abrir(
      WidgetTester tester, {
      Map<String, (int, String)>? rutas,
    }) async {
      final pedidos = <http.Request>[];
      await montarAdmin(
        tester,
        inicio: '/admin/espacios/nuevo',
        api: apiRutas(rutas ?? rutasDeEspacios(), pedidos: pedidos),
      );
      return pedidos;
    }

    Future<void> completar(WidgetTester tester) async {
      await elegir(tester, 'Sede', 'Sede Morón');
      await elegir(tester, 'Deporte', 'Fútbol');
      await elegir(tester, 'Tipo', 'Fútbol 5');
      await elegir(tester, 'Condición', 'Al aire libre');
      await elegir(tester, 'Iluminación', 'Iluminada');
      await tester.enterText(find.bySemanticsLabel('Precio por hora'), '38000');
      await tester.pumpAndSettle();
    }

    testWidgets('guardar sin nada marca los seis campos y no envía', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      expect(find.text('Este campo es obligatorio'), findsNWidgets(6));
      expect(pedidos.where((p) => p.method == 'POST'), isEmpty);
      semantica.dispose();
    });

    testWidgets(
      'el tipo se elige después del deporte y cambiar de deporte lo borra',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester);
        await tester.tap(find.bySemanticsLabel('Tipo'));
        await tester.pumpAndSettle();
        expect(find.byType(Dialog), findsNothing);

        await elegir(tester, 'Deporte', 'Fútbol');
        await elegir(tester, 'Tipo', 'Fútbol 7');
        expect(find.text('Fútbol 7'), findsOneWidget);
        await elegir(tester, 'Deporte', 'Tenis');
        expect(find.text('Fútbol 7'), findsNothing);
        expect(find.text('Seleccioná el tipo'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets(
      'con sede, deporte y tipo muestra el nombre que calcula la API',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await abrir(tester);
        await elegir(tester, 'Sede', 'Sede Morón');
        expect(find.text('Falta el deporte'), findsOneWidget);
        await elegir(tester, 'Deporte', 'Fútbol');
        expect(find.text('Falta el tipo de cancha'), findsOneWidget);
        await elegir(tester, 'Tipo', 'Fútbol 5');
        expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets('guarda y muestra el espacio creado', (tester) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(tester);
      await completar(tester);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      final alta = pedidos.singleWhere((p) => p.method == 'POST');
      expect(jsonDecode(alta.body), containsPair('numero', 1));
      expect(find.text('¡Espacio deportivo creado!'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('si el número ya se tomó, avisa y muestra el siguiente', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrir(
        tester,
        rutas: rutasDeEspacios(
          alta: (
            409,
            '{"errores": {"nombre": "Ya existe un espacio deportivo con ese nombre '
                'en la sede seleccionada."}, '
                '"nombre": "Moron_Rivadavia_19850_Futbol_F5_2", "numero": 2}',
          ),
        ),
      );
      await completar(tester);
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
      semantica.dispose();
    });

    testWidgets(
      'si no se puede calcular el nombre, lo dice y deja reintentar',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final pedidos = await abrir(
          tester,
          rutas: {...rutasDeEspacios(), 'GET /espacios/nombre': (500, '{}')},
        );
        await elegir(tester, 'Sede', 'Sede Morón');
        await elegir(tester, 'Deporte', 'Fútbol');
        await elegir(tester, 'Tipo', 'Fútbol 5');
        expect(find.text('No se pudo calcular el nombre'), findsOneWidget);
        expect(find.text('Falta el tipo de cancha'), findsNothing);
        await tester.tap(find.text('REINTENTAR'));
        await tester.pumpAndSettle();
        expect(
          pedidos.where((p) => p.url.path == '/espacios/nombre'),
          hasLength(2),
        );
        semantica.dispose();
      },
    );

    testWidgets('guardar sin nombre calculado avisa del error del servidor', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrir(
        tester,
        rutas: {...rutasDeEspacios(), 'GET /espacios/nombre': (500, '{}')},
      );
      await completar(tester);
      await tester.ensureVisible(find.text('GUARDAR ESPACIO'));
      await tester.tap(find.text('GUARDAR ESPACIO'));
      await tester.pumpAndSettle();
      expect(find.text('Error del servidor'), findsOneWidget);
      expect(pedidos.where((p) => p.method == 'POST'), isEmpty);
      semantica.dispose();
    });

    testWidgets('si la sesión venció al calcular el nombre, lo avisa', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrir(
        tester,
        rutas: {...rutasDeEspacios(), 'GET /espacios/nombre': (401, '{}')},
      );
      await elegir(tester, 'Sede', 'Sede Morón');
      await elegir(tester, 'Deporte', 'Fútbol');
      await elegir(tester, 'Tipo', 'Fútbol 5');
      expect(find.text('Tu sesión expiró'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('sin sedes lo dice y no deja elegir', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester, rutas: rutasDeEspacios(sedes: '[]'));
      expect(find.text('Todavía no hay sedes'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Sede'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      semantica.dispose();
    });

    testWidgets('el éxito sin el espacio guardado lleva al listado', (
      tester,
    ) async {
      await montarAdmin(
        tester,
        inicio: '/admin/espacios/creado',
        api: apiRutas(rutasDeEspacios()),
      );
      expect(find.text('¡Espacio deportivo creado!'), findsNothing);
      expect(find.text('ALTA ESPACIO'), findsOneWidget);
    });
  });

  testWidgets('un usuario no entra al alta de espacios', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: apiRutas({}),
        session: SesionFalsa(perfilUsuario),
        appearance: Appearance.inMemory(),
        initialLocation: '/admin/espacios/nuevo',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nuevo espacio deportivo'), findsNothing);
    expect(find.text('Acceso denegado'), findsOneWidget);
  });
}
