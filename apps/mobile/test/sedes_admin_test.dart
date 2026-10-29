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

import 'soporte/admin.dart';
import 'soporte/montar.dart';

void main() {
  group('días de la semana', () {
    late AppLocalizations es;
    String texto(List<int> dias) => weekdaysText(es, weekdaysLabel(dias));

    setUpAll(() async {
      es = await AppLocalizations.delegate.load(const Locale('es'));
    });

    test('los tramos seguidos desde el lunes se nombran', () {
      expect(texto([7, 6, 5, 4, 3, 2, 1]), 'Lunes a domingo');
      expect(texto([1, 2, 3, 4, 5, 6]), 'Lunes a sábado');
      expect(texto([1, 2, 3, 4, 5]), 'Lunes a viernes');
    });

    test('los días sueltos van abreviados y en orden', () {
      expect(texto([5, 1, 3]), 'Lun, Mié, Vie');
      expect(texto([6, 7]), 'Sáb, Dom');
    });
  });

  group('Sedes', () {
    Venues sedes(ApiClient api) => Venues(
      repository: VenuesRepository(api: api, session: SesionFalsa(perfilAdmin)),
    );

    test('lee las sedes activas', () async {
      final api = apiRutas({
        'GET /sedes': (200, '{"sedes": [$sedeMoronJson, $sedeHaedoJson]}'),
      });
      final leidas = await sedes(api).repository.active();
      expect([for (final s in leidas) s.name], ['Sede Morón', 'Sede Haedo']);
      expect(
        weekdaysText(
          await AppLocalizations.delegate.load(const Locale('es')),
          leidas.first.daysLabel,
        ),
        'Lunes a sábado',
      );
      expect(leidas.first.spaceCount, 1);
    });

    test('una respuesta que no se entiende es un error del servidor', () {
      final api = apiRutas({
        'GET /sedes': (
          200,
          '{"sedes": [{"id": "00000000-0000-7000-8000-000000000001"}]}',
        ),
      });
      expect(sedes(api).repository.active(), throwsA(isA<ErrorDelServidor>()));
    });

    test('el alta manda los datos y devuelve la sede guardada', () async {
      final pedidos = <http.Request>[];
      final api = apiRutas({
        'POST /sedes': (201, sedeHaedoJson),
      }, pedidos: pedidos);
      final sede = await sedes(api).create(
        name: 'Sede Haedo',
        address: 'Av. Vergara 1850',
        opening: '08:00',
        closing: '23:00',
        days: const [1, 2, 3, 4, 5, 6, 7],
      );
      expect(sede.id, '00000000-0000-7000-8000-000000000005');
      expect(pedidos.single.headers['authorization'], 'Bearer token-falso');
      expect(jsonDecode(pedidos.single.body), {
        'nombre': 'Sede Haedo',
        'direccion': 'Av. Vergara 1850',
        'apertura': '08:00',
        'cierre': '23:00',
        'dias': [1, 2, 3, 4, 5, 6, 7],
      });
    });

    Future<Venue> alta(ApiClient api) => sedes(api).create(
      name: 'Sede Haedo',
      address: 'Av. Vergara 1850',
      opening: '08:00',
      closing: '23:00',
      days: const [1, 2, 3, 4, 5, 6, 7],
    );

    test('un nombre repetido vuelve con el mensaje del campo', () {
      final api = apiRutas({
        'POST /sedes': (
          409,
          '{"errores": {"nombre": "Ya existe una sede con ese nombre"}}',
        ),
      });
      expect(
        alta(api),
        throwsA(
          isA<VenueRejected>().having((e) => e.errors, 'errores', {
            'nombre': 'Ya existe una sede con ese nombre',
          }),
        ),
      );
    });

    test('sin sesión válida avisa que venció', () {
      final api = apiRutas({'POST /sedes': (401, '{}')});
      expect(alta(api), throwsA(isA<SessionExpired>()));
    });

    test('un 403 no es un alta: es un error', () {
      final api = apiRutas({'POST /sedes': (403, '')});
      expect(alta(api), throwsA(isA<ErrorDelServidor>()));
    });
  });

  group('panel de sedes', () {
    testWidgets('sin sedes lo dice y deja agregar la primera', (tester) async {
      await montarAdmin(
        tester,
        api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
      );
      expect(find.text('0 SEDES ACTIVAS'), findsOneWidget);
      expect(find.text('Todavía no hay sedes'), findsOneWidget);
      expect(find.text('AGREGAR SEDE'), findsOneWidget);
    });

    testWidgets('cada sede con sus canchas, días y horario', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarAdmin(
        tester,
        api: apiRutas({
          'GET /sedes': (200, '{"sedes": [$sedeMoronJson, $sedeHaedoJson]}'),
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
      semantica.dispose();
    });

    testWidgets('sin conexión avisa y deja reintentar', (tester) async {
      var intentos = 0;
      final api = ApiClient(
        'http://api.falsa',
        cliente: _Cliente((_) async {
          intentos++;
          if (intentos == 1) throw const _Corte();
          return http.Response('{"sedes": []}', 200);
        }),
      );
      await montarAdmin(tester, api: api);
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

  group('alta de sede', () {
    Future<List<http.Request>> abrirAlta(
      WidgetTester tester, {
      (int, String) respuesta = (201, sedeHaedoJson),
    }) async {
      final pedidos = <http.Request>[];
      await montarAdmin(
        tester,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({
          'POST /sedes': respuesta,
          'GET /sedes': (200, '{"sedes": [$sedeHaedoJson]}'),
        }, pedidos: pedidos),
      );
      return pedidos;
    }

    Future<void> completar(WidgetTester tester) async {
      await tester.enterText(
        find.bySemanticsLabel('Nombre de la sede'),
        'Sede Haedo',
      );
      await tester.enterText(
        find.bySemanticsLabel('Dirección'),
        'Av. Vergara 1850',
      );
      await elegir(tester, 'Horario de apertura', '08:00');
      await elegir(tester, 'Horario de cierre', '23:00');
    }

    testWidgets('guardar sin nada marca todo lo que falta y no envía', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrirAlta(tester);
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      expect(find.text('La dirección es obligatoria'), findsOneWidget);
      expect(
        find.text('El horario de apertura es obligatorio'),
        findsOneWidget,
      );
      expect(find.text('El horario de cierre es obligatorio'), findsOneWidget);
      expect(pedidos.where((p) => p.method == 'POST'), isEmpty);
      semantica.dispose();
    });

    testWidgets(
      'un campo que se deja vacío no se marca hasta intentar guardar',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await abrirAlta(tester);
        await tester.tap(find.bySemanticsLabel('Dirección'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Nombre de la sede'));
        await tester.pumpAndSettle();
        expect(find.text('La dirección es obligatoria'), findsNothing);
        await tester.tap(find.text('GUARDAR SEDE'));
        await tester.pumpAndSettle();
        expect(find.text('La dirección es obligatoria'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets('una dirección escrita a medias se marca al salir de ella', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrirAlta(tester);
      await tester.enterText(find.bySemanticsLabel('Dirección'), 'Av. Vergara');
      await tester.tap(find.bySemanticsLabel('Nombre de la sede'));
      await tester.pumpAndSettle();
      expect(find.text('Escribí la calle y la altura'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('la dirección necesita la altura', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrirAlta(tester);
      await completar(tester);
      await tester.enterText(find.bySemanticsLabel('Dirección'), 'Av. Vergara');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('Escribí la calle y la altura'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('el cierre va después de la apertura, salvo la medianoche', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrirAlta(tester);
      await elegir(tester, 'Horario de apertura', '18:00');
      await elegir(tester, 'Horario de cierre', '10:00');
      expect(
        find.text('El cierre tiene que ser después de la apertura'),
        findsOneWidget,
      );
      await elegir(tester, 'Horario de cierre', '00:00');
      expect(
        find.text('El cierre tiene que ser después de la apertura'),
        findsNothing,
      );
      semantica.dispose();
    });

    testWidgets('guarda con los días elegidos y muestra la sede creada', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final pedidos = await abrirAlta(tester);
      await completar(tester);
      await elegir(tester, 'Días que abre', 'Lunes a viernes');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      final alta = pedidos.singleWhere((p) => p.method == 'POST');
      expect(jsonDecode(alta.body), {
        'nombre': 'Sede Haedo',
        'direccion': 'Av. Vergara 1850',
        'apertura': '08:00',
        'cierre': '23:00',
        'dias': [1, 2, 3, 4, 5],
      });
      expect(find.text('¡Sede creada!'), findsOneWidget);
      expect(find.text('Sede Haedo · Av. Vergara 1850'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('un nombre repetido se marca en el campo hasta que se cambia', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrirAlta(
        tester,
        respuesta: (
          409,
          '{"errores": {"nombre": "Ya existe una sede con ese nombre"}}',
        ),
      );
      await completar(tester);
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una sede con ese nombre'), findsOneWidget);
      await tester.enterText(
        find.bySemanticsLabel('Nombre de la sede'),
        'Sede Haedo Norte',
      );
      await tester.pumpAndSettle();
      expect(find.text('Ya existe una sede con ese nombre'), findsNothing);
      semantica.dispose();
    });

    testWidgets('el éxito sin la sede guardada lleva al listado', (
      tester,
    ) async {
      await montarAdmin(
        tester,
        inicio: '/admin/sedes/creada',
        api: apiRutas({'GET /sedes': (200, '{"sedes": [$sedeHaedoJson]}')}),
      );
      expect(find.text('¡Sede creada!'), findsNothing);
      expect(find.text('1 SEDE ACTIVA'), findsOneWidget);
    });
  });

  group('alta y listado juntos', () {
    Future<void> cargarYGuardar(WidgetTester tester) async {
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
      await elegir(tester, 'Horario de apertura', '08:00');
      await elegir(tester, 'Horario de cierre', '23:00');
      await tester.tap(find.text('GUARDAR SEDE'));
      await tester.pumpAndSettle();
    }

    testWidgets('al volver del alta, el listado ya muestra la sede nueva', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      var guardada = false;
      final api = ApiClient(
        'http://api.falsa',
        cliente: _Cliente((pedido) async {
          if (pedido.method == 'POST') {
            guardada = true;
            return http.Response(sedeHaedoJson, 201);
          }
          return http.Response(
            guardada ? '{"sedes": [$sedeHaedoJson]}' : '{"sedes": []}',
            200,
          );
        }),
      );
      await montarAdmin(tester, api: api);
      expect(find.text('0 SEDES ACTIVAS'), findsOneWidget);
      await cargarYGuardar(tester);
      expect(find.text('¡Sede creada!'), findsOneWidget);
      await tester.tap(find.text('IR AL LISTADO'));
      await tester.pumpAndSettle();
      expect(find.text('1 SEDE ACTIVA'), findsOneWidget);
      expect(find.text('Sede Haedo'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('si el listado de abajo no carga, no tapa el éxito', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      var lecturas = 0;
      final api = ApiClient(
        'http://api.falsa',
        cliente: _Cliente((pedido) async {
          if (pedido.method == 'POST') return http.Response(sedeHaedoJson, 201);
          lecturas++;
          if (lecturas > 1) throw const _Corte();
          return http.Response('{"sedes": []}', 200);
        }),
      );
      await montarAdmin(tester, api: api);
      await cargarYGuardar(tester);
      expect(find.text('¡Sede creada!'), findsOneWidget);
      expect(find.text('Error de conexión'), findsNothing);
      semantica.dispose();
    });

    testWidgets(
      'si el alta se guardó pero la respuesta no llegó, el reintento muestra el éxito',
      (tester) async {
        final semantica = tester.ensureSemantics();
        var altas = 0;
        final api = ApiClient(
          'http://api.falsa',
          cliente: _Cliente((pedido) async {
            if (pedido.method == 'POST') {
              altas++;
              if (altas == 1) throw const _Corte();
              return http.Response(
                '{"errores": {"nombre": "Ya existe una sede con ese nombre"}}',
                409,
              );
            }
            return http.Response(
              altas == 0 ? '{"sedes": []}' : '{"sedes": [$sedeHaedoJson]}',
              200,
            );
          }),
        );
        await montarAdmin(tester, api: api);
        await cargarYGuardar(tester);
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
        semantica.dispose();
      },
    );
  });

  testWidgets('un usuario no entra al panel de sedes', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: apiRutas({}),
        session: SesionFalsa(perfilUsuario),
        appearance: Appearance.inMemory(),
        initialLocation: '/admin/sedes/nueva',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nueva sede'), findsNothing);
    expect(find.text('Acceso denegado'), findsOneWidget);
  });
}

class _Corte implements Exception {
  const _Corte();
}

class _Cliente extends http.BaseClient {
  _Cliente(this._responder);

  final Future<http.Response> Function(http.BaseRequest) _responder;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _responder(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(r.body)),
      r.statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
