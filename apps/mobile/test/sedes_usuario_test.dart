import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/sedes/sede.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  setUpAll(cargarFuentes);

  test('la sede lee sus deportes, y sin ellos queda vacía', () {
    final con = Sede.desdeJson({
      'id': 1,
      'nombre': 'Sede Morón',
      'direccion': 'Av. Rivadavia 19850',
      'apertura': '08:00',
      'cierre': '23:00',
      'dias': [1, 2],
      'canchas': 2,
      'deportes': ['Futbol', 'Tenis'],
    });
    expect(con?.deportes, ['Futbol', 'Tenis']);
    final sin = Sede.desdeJson({
      'id': 1,
      'nombre': 'Sede Morón',
      'direccion': 'Av. Rivadavia 19850',
      'apertura': '08:00',
      'cierre': '23:00',
      'dias': [1, 2],
      'canchas': 0,
    });
    expect(sin?.deportes, isEmpty);
  });

  group('todas las sedes', () {
    testWidgets('cada sede con horario, canchas y deportes', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(tester, api: apiRutas(rutasDeSedes()));
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
      semantica.dispose();
    });

    testWidgets('sin sedes lo dice', (tester) async {
      await montarUsuario(tester, api: apiRutas(rutasDeSedes(sedes: '[]')));
      expect(find.text('Todavía no hay sedes'), findsOneWidget);
      expect(find.text('El club todavía no cargó sus sedes.'), findsOneWidget);
    });

    testWidgets('si el servidor falla no queda nada a la vista', (
      tester,
    ) async {
      await montarUsuario(
        tester,
        api: apiRutas({...rutasDeSedes(), 'GET /sedes': (500, '{}')}),
      );
      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('Ver canchas'), findsNothing);
    });
  });

  group('una sede', () {
    testWidgets('muestra la portada, el contador y cada cancha', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final pedidos = <http.Request>[];
      await montarUsuario(
        tester,
        inicio: '/sedes/1',
        api: apiRutas(rutasDeSedes(), pedidos: pedidos),
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
      final canchas = pedidos.where((p) => p.url.path == '/espacios').single;
      expect(canchas.url.queryParameters, {'sede_id': '1'});
      semantica.dispose();
    });

    testWidgets('sin canchas lo dice con el contador en cero', (tester) async {
      await montarUsuario(
        tester,
        inicio: '/sedes/5',
        api: apiRutas(rutasDeSedes(espacios: '[]')),
      );
      expect(find.text('0 CANCHAS'), findsOneWidget);
      expect(find.text('Todavía no hay canchas'), findsOneWidget);
      expect(find.text('VER HORARIOS / RESERVAR'), findsNothing);
    });

    testWidgets('una sede que ya no está vuelve al listado con el aviso', (
      tester,
    ) async {
      await montarUsuario(
        tester,
        inicio: '/sedes/99',
        api: apiRutas(rutasDeSedes()),
      );
      expect(find.text('Esta sede ya no está disponible'), findsOneWidget);
      expect(find.text('Sedes'), findsOneWidget);
    });

    testWidgets('«Todas las sedes» vuelve al listado', (tester) async {
      await montarUsuario(tester, api: apiRutas(rutasDeSedes(espacios: '[]')));
      await tester.tap(find.text('SEDE HAEDO'));
      await tester.pumpAndSettle();
      expect(find.text('0 CANCHAS'), findsOneWidget);
      await tester.tap(find.text('Todas las sedes'));
      await tester.pumpAndSettle();
      expect(find.text('0 CANCHAS'), findsNothing);
      expect(find.text('SEDE HAEDO'), findsOneWidget);
    });

    testWidgets('sin conexión avisa y reintenta', (tester) async {
      var intentos = 0;
      final api = ClienteApi(
        'http://api.falsa',
        cliente: _Cliente((pedido) async {
          final ruta = pedido.url.path;
          if (ruta == '/espacios' && intentos++ == 0) throw const _Corte();
          final (codigo, cuerpo) = rutasDeSedes()['GET $ruta'] ?? (404, '{}');
          return http.Response.bytes(utf8.encode(cuerpo), codigo);
        }),
      );
      await montarUsuario(tester, inicio: '/sedes/1', api: api);
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

  group('filtro', () {
    const f7 =
        '{"id": 12, "nombre": "Moron_Rivadavia_19850_Futbol_F7_1", "sede_id": 1, '
        '"sede": "Sede Morón", "deporte": "Futbol", "tipo": "F7", "numero": 1, '
        '"techada": false, "iluminada": true, "precio_por_hora": 55000}';

    /// Una API que responde a `GET /espacios` según el deporte y el tipo del pedido.
    ClienteApi api({
      List<http.Request>? pedidos,
      bool fallaAlFiltrar = false,
    }) => ClienteApi(
      'http://api.falsa',
      cliente: _Cliente((pedido) async {
        pedidos?.add(pedido as http.Request);
        final ruta = pedido.url.path;
        final q = pedido.url.queryParameters;
        if (ruta == '/espacios') {
          if (fallaAlFiltrar && q.containsKey('deporte')) {
            return http.Response('{}', 500);
          }
          final todas = [espacioF5Json, f7, espacioTenisJson];
          final quedan = [
            for (final e in todas)
              if ((q['deporte'] == null ||
                      e.contains('"deporte": "${q['deporte']}"')) &&
                  (q['tipo'] == null || e.contains('"tipo": "${q['tipo']}"')))
                e,
          ];
          return http.Response.bytes(
            utf8.encode('{"espacios": [${quedan.join(', ')}]}'),
            200,
          );
        }
        final (codigo, cuerpo) = rutasDeSedes()['GET $ruta'] ?? (404, '{}');
        return http.Response.bytes(utf8.encode(cuerpo), codigo);
      }),
    );

    Future<void> tocarChip(WidgetTester tester, String etiqueta) async {
      await tester.ensureVisible(find.bySemanticsLabel(etiqueta));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(etiqueta));
      await tester.pumpAndSettle();
    }

    testWidgets('deporte, tipo, «Todos» y quitar el deporte', (tester) async {
      final semantica = tester.ensureSemantics();
      final pedidos = <http.Request>[];
      await montarUsuario(
        tester,
        inicio: '/sedes/1',
        api: api(pedidos: pedidos),
      );
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsNothing);

      await tocarChip(tester, 'Deporte Fútbol');
      expect(find.text('2 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsOneWidget);
      expect(pedidos.last.url.queryParameters, {
        'sede_id': '1',
        'deporte': 'Futbol',
      });

      await tocarChip(tester, 'Tipo Fútbol 7');
      expect(find.text('1 CANCHA · FÚTBOL 7'), findsOneWidget);
      expect(find.text('Moron_Rivadavia_19850_Futbol_F5_1'), findsNothing);

      await tocarChip(tester, 'Tipo Todos');
      expect(find.text('2 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);

      await tocarChip(tester, 'Deporte Fútbol');
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      semantica.dispose();
    });

    testWidgets('quitar el deporte vuelve a preguntar y trae lo nuevo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final datos = [espacioF5Json, espacioTenisJson];
      final pedidos = <http.Request>[];
      final cliente = ClienteApi(
        'http://api.falsa',
        cliente: _Cliente((pedido) async {
          pedidos.add(pedido as http.Request);
          final ruta = pedido.url.path;
          final q = pedido.url.queryParameters;
          if (ruta == '/espacios') {
            final quedan = [
              for (final e in datos)
                if ((q['deporte'] == null ||
                        e.contains('"deporte": "${q['deporte']}"')) &&
                    (q['tipo'] == null || e.contains('"tipo": "${q['tipo']}"')))
                  e,
            ];
            return http.Response.bytes(
              utf8.encode('{"espacios": [${quedan.join(', ')}]}'),
              200,
            );
          }
          final (codigo, cuerpo) = rutasDeSedes()['GET $ruta'] ?? (404, '{}');
          return http.Response.bytes(utf8.encode(cuerpo), codigo);
        }),
      );
      await montarUsuario(tester, inicio: '/sedes/1', api: cliente);
      await tocarChip(tester, 'Deporte Fútbol');
      expect(find.text('1 CANCHA · FÚTBOL'), findsOneWidget);

      // Otro administrador carga un Fútbol 7 mientras tanto.
      datos.add(f7);
      await tocarChip(tester, 'Deporte Fútbol');
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(pedidos.last.url.queryParameters, {'sede_id': '1'});

      // Al volver a elegir el deporte aparece el tipo nuevo.
      await tocarChip(tester, 'Deporte Fútbol');
      expect(find.text('2 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);
      expect(find.bySemanticsLabel('Tipo Fútbol 7'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('un deporte con un solo tipo no muestra la barra de tipos', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(tester, inicio: '/sedes/1', api: api());
      await tocarChip(tester, 'Deporte Tenis');
      expect(find.text('1 CANCHA · TENIS'), findsOneWidget);
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      semantica.dispose();
    });

    testWidgets('si filtrar falla, avisa y queda como estaba', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        inicio: '/sedes/1',
        api: api(fallaAlFiltrar: true),
      );
      await tocarChip(tester, 'Deporte Fútbol');
      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('3 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      semantica.dispose();
    });
  });

  group('horarios', () {
    testWidgets('llega con la cancha elegida entre las de su tipo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(
        tester,
        inicio: '/sedes/1',
        api: apiRutas(rutasDeSedes()),
      );
      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      expect(find.text('SELECCIONÁ CANCHA'), findsOneWidget);
      expect(find.text('Fútbol 5'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Moron_Rivadavia_19850_Futbol_F5_1, Cancha 1, Al aire libre, elegida',
        ),
        findsOneWidget,
      );
      // La de tenis no es de ese tipo.
      expect(find.textContaining('Tenis_PDL'), findsNothing);
      semantica.dispose();
    });
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
      Stream.value(r.bodyBytes),
      r.statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }
}
