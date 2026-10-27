import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/dorsal.dart';
import 'package:clubnahuelmosse/comun/ficha_socio.dart';
import 'package:clubnahuelmosse/comun/isotipo.dart';
import 'package:clubnahuelmosse/comun/linea_del_dia.dart';
import 'package:clubnahuelmosse/comun/marcador.dart';
import 'package:clubnahuelmosse/comun/reserva_pendiente.dart';
import 'package:clubnahuelmosse/comun/tile_deporte.dart';
import 'package:clubnahuelmosse/comun/troquel.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/pantalla_mis_reservas.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/fotos.dart';
import 'package:clubnahuelmosse/sedes/pantalla_sedes.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/sesion/pantalla_inicio_sesion.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

const _oscura = Paleta.oscura;

const _claveBorde = ValueKey('borde-reserva-activa');

const _catalogo =
    '{"deportes": ['
    '{"clave": "Futbol", "nombre": "Fútbol", "tipos": ['
    '{"clave": "F5", "nombre": "Fútbol 5"}]}, '
    '{"clave": "Tenis", "nombre": "Tenis", "tipos": ['
    '{"clave": "PDL", "nombre": "Polvo de ladrillo"}]}, '
    '{"clave": "Padel", "nombre": "Pádel", "tipos": [{"clave": "PAD", "nombre": "Pádel"}]}, '
    '{"clave": "Voley", "nombre": "Vóley", "tipos": [{"clave": "IND", "nombre": "Indoor"}]}, '
    '{"clave": "Basquet", "nombre": "Básquet", "tipos": [{"clave": "B5", "nombre": "Básquet 5"}]}, '
    '{"clave": "Hockey", "nombre": "Hockey", "tipos": [{"clave": "H7", "nombre": "Hockey 7"}]}, '
    '{"clave": "Golf", "nombre": "Golf", "tipos": [{"clave": "DR", "nombre": "Driving range"}]}'
    ']}';

const _catalogoConDesconocido =
    '{"deportes": ['
    '{"clave": "Futbol", "nombre": "Fútbol", "tipos": ['
    '{"clave": "F5", "nombre": "Fútbol 5"}]}, '
    '{"clave": "Rugby", "nombre": "Rugby", "tipos": ['
    '{"clave": "R7", "nombre": "Rugby 7"}]}'
    ']}';

String _sede(String id, String nombre, String direccion, int canchas) =>
    '{"id": "$id", "nombre": "$nombre", "direccion": "$direccion", '
    '"apertura": "08:00", "cierre": "23:00", "dias": [1, 2, 3, 4, 5, 6, 7], '
    '"canchas": $canchas, "deportes": ["Futbol", "Tenis"]}';

final _sedes =
    '{"sedes": [${_sede('00000000-0000-7000-8000-000000000001', 'Sede Haedo', 'Av. Vergara 1850', 6)}, '
    '${_sede('00000000-0000-7000-8000-000000000002', 'Sede Morón', 'Av. Rivadavia 19850', 4)}, '
    '${_sede('00000000-0000-7000-8000-000000000003', 'Sede Castelar', 'Av. Santa Rosa 1200', 4)}, '
    '${_sede('00000000-0000-7000-8000-000000000004', 'Sede Ituzaingó', 'Blas Parera 300', 3)}]}';

/// Un instante del club: [dia] de noviembre de 2026 a las [hora]:[minuto] (UTC−3).
DateTime _delClub(int dia, int hora, [int minuto = 0]) =>
    DateTime.utc(2026, 11, dia, hora + 3, minuto);

String _uuid(int n) => '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

String _reserva({
  String id = '00000000-0000-7000-8000-000000000001',
  DateTime? inicio,
  String estado = 'activa',
  String? motivo,
}) {
  final desde = inicio ?? _delClub(12, 21);
  final hasta = desde.add(const Duration(hours: 1));
  return '{"id": "$id", "espacio_id": "00000000-0000-7000-8000-000000000009", "sede_id": "00000000-0000-7000-8000-000000000002", '
      '"espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", '
      '"tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
      '"inicio": "${desde.toIso8601String()}", "fin": "${hasta.toIso8601String()}", '
      '"precio_por_hora": 38000, "total": 38000, "estado": "$estado", '
      '"motivo": ${motivo == null ? 'null' : '"$motivo"'}, '
      '"cancelable": ${estado == 'activa'}}';
}

Future<void> _montarInicio(
  WidgetTester tester, {
  List<String>? reservas,
  String? siguiente,
  String catalogo = _catalogo,
  ThemeData? tema,
  Size tamano = const Size(393, 852),
}) {
  final sesion = SesionFalsa(perfilUsuario);
  final lista = (reservas ?? [_reserva()]).join(', ');
  final api = apiRutas({
    'GET /reservas': (
      200,
      '{"reservas": [$lista]'
          '${siguiente == null ? '' : ', "siguiente": "$siguiente"'}}',
    ),
    'GET /espacios/catalogo': (200, catalogo),
    'GET /sedes': (200, _sedes),
  });
  return montar(
    tester,
    PantallaInicio(
      sesion: sesion,
      reservas: Reservas(api: api, sesion: sesion),
      espacios: Espacios(api: api, sesion: sesion),
      sedes: Sedes(api: api, sesion: sesion),
    ),
    tema: tema ?? temaOscuro,
    tamano: tamano,
  );
}

Future<void> _montarMisReservas(
  WidgetTester tester, {
  String proximas = '[]',
  String historial = '[]',
  String inicio = '/reservas',
  bool oscuro = true,
}) {
  final rutas = rutasDeSedes();
  return montarUsuario(
    tester,
    inicio: inicio,
    oscuro: oscuro,
    tamano: const Size(393, 1600),
    api: ClienteApi(
      'http://api.falsa',
      cliente: MockClient((pedido) async {
        final (c, cuerpo) = pedido.url.path == '/reservas'
            ? (
                200,
                '{"reservas": ${pedido.url.queryParameters['cuando'] == 'historial' ? historial : proximas}}',
              )
            : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
        return http.Response.bytes(
          utf8.encode(cuerpo),
          c,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );
}

Finder _enElMarcador(Finder hijo) =>
    find.descendant(of: find.byType(Marcador), matching: hijo);

Color? _colorDeCifra(WidgetTester tester, String cifra) =>
    tester.widget<Text>(_enElMarcador(find.text(cifra))).style?.color;

Color? _colorDelBorde(WidgetTester tester, Finder borde) {
  final w = tester.widget(borde);
  if (w is Container) {
    return w.color ?? (w.decoration as BoxDecoration?)?.color;
  }
  if (w is DecoratedBox) return (w.decoration as BoxDecoration).color;
  if (w is ColoredBox) return w.color;
  final caja = find.descendant(of: borde, matching: find.byType(DecoratedBox));
  if (caja.evaluate().isNotEmpty) {
    return (tester.widget<DecoratedBox>(caja.first).decoration as BoxDecoration)
        .color;
  }
  return tester
      .widget<ColoredBox>(
        find.descendant(of: borde, matching: find.byType(ColoredBox)).first,
      )
      .color;
}

bool _conContornoDeFoco(WidgetTester tester, Finder tarjeta) => tester
    .widgetList<DecoratedBox>(
      find.descendant(of: tarjeta, matching: find.byType(DecoratedBox)),
    )
    .any(
      (c) =>
          c.decoration is BoxDecoration &&
          (c.decoration as BoxDecoration).border?.top.color ==
              _oscura.borderFocus,
    );

Finder _enLaTarjeta(Finder hijo) =>
    find.descendant(of: find.byType(TarjetaReserva), matching: hijo);

const _cuentas = ['HOY', 'MAÑANA', 'FALTAN 2 DÍAS'];

void _sinCuenta() {
  for (final texto in _cuentas) {
    expect(find.text(texto), findsNothing, reason: texto);
  }
}

void main() {
  setUpAll(cargarFuentes);

  group('inicio', () {
    testWidgets(
      'el hero del inicio lleva el marcador con sedes, canchas y próximas @RED-03-S1',
      (tester) async {
        await _montarInicio(tester);

        expect(find.byType(Marcador), findsOneWidget);
        final celdas = tester.widget<Marcador>(find.byType(Marcador)).celdas;
        expect(
          [for (final c in celdas) (c.rotulo.toUpperCase(), c.cifra)],
          [('SEDES', '04'), ('CANCHAS', '17'), ('PRÓXIMAS', '01')],
        );
        for (final texto in [
          'SEDES',
          'CANCHAS',
          'PRÓXIMAS',
          '04',
          '17',
          '01',
        ]) {
          expect(
            _enElMarcador(find.text(texto)),
            findsOneWidget,
            reason: texto,
          );
        }
        expect(
          tester.getTopLeft(find.byType(Marcador)).dy,
          lessThan(tester.getTopLeft(find.text('TU PRÓXIMA RESERVA')).dy),
        );
      },
    );

    testWidgets(
      'la sección deportes muestra un tile por deporte del catálogo @RED-03-S1',
      (tester) async {
        await _montarInicio(tester);

        const esperados = [
          ('Futbol', 'Fútbol', '⚽'),
          ('Tenis', 'Tenis', '🎾'),
          ('Padel', 'Pádel', '🏓'),
          ('Voley', 'Vóley', '🏐'),
          ('Basquet', 'Básquet', '🏀'),
          ('Hockey', 'Hockey', '🏑'),
          ('Golf', 'Golf', '⛳'),
        ];
        expect(find.text('DEPORTES'), findsOneWidget);
        expect(find.byType(TileDeporte), findsNWidgets(esperados.length));
        for (final (i, (clave, nombre, emoji)) in esperados.indexed) {
          final tile = find.byType(TileDeporte).at(i);
          final widget = tester.widget<TileDeporte>(tile);
          expect(widget.nombre, nombre);
          expect(widget.emoji, emoji, reason: clave);
          expect(widget.imagen, fotoDeDeporte(clave), reason: clave);
          expect(
            find.descendant(of: tile, matching: find.text(nombre)),
            findsOneWidget,
          );
          expect(
            find.descendant(of: tile, matching: find.byType(Image)),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'la celda destacada del marcador es PRÓXIMAS y cuenta las reservas activas por venir @RED-03-ASM-01',
      (tester) async {
        await _montarInicio(
          tester,
          reservas: [
            _reserva(id: '00000000-0000-7000-8000-000000000001', inicio: _delClub(12, 21)),
            _reserva(id: '00000000-0000-7000-8000-000000000002', inicio: _delClub(13, 10)),
            _reserva(id: '00000000-0000-7000-8000-000000000003', inicio: _delClub(14, 10)),
          ],
        );

        final celdas = tester.widget<Marcador>(find.byType(Marcador)).celdas;
        final destacadas = celdas.where((c) => c.destacada).toList();
        expect(destacadas, hasLength(1));
        expect(destacadas.single.rotulo.toUpperCase(), 'PRÓXIMAS');
        expect(destacadas.single.cifra, '03');
        expect(_colorDeCifra(tester, '03'), _oscura.accentOnMedia);
        expect(_colorDeCifra(tester, '04'), _oscura.textOnMedia);
        expect(find.text('LIBRES HOY'), findsNothing);
      },
    );

    testWidgets(
      'el marcador reemplaza «N sedes · N canchas · disponibilidad en tiempo real» y pone las cifras con dos dígitos, 04 @RED-03-ASM-02',
      (tester) async {
        await _montarInicio(tester);

        expect(
          find.text('4 sedes · 17 canchas · disponibilidad en tiempo real'),
          findsNothing,
        );
        expect(
          find.textContaining('disponibilidad en tiempo real'),
          findsNothing,
        );
        expect(_enElMarcador(find.text('04')), findsOneWidget);
        expect(_enElMarcador(find.text('17')), findsOneWidget);
        expect(find.text('4'), findsNothing);
      },
    );

    testWidgets(
      'los tiles usan las fotos de la app, no navegan y se anuncian sólo por su nombre @RED-03-ASM-03',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _montarInicio(tester);

        for (final tile in tester.widgetList<TileDeporte>(
          find.byType(TileDeporte),
        )) {
          expect(tile.alTocar, isNull, reason: tile.nombre);
          expect(tile.elegido, isFalse, reason: tile.nombre);
        }
        expect(find.text('ELEGIDO'), findsNothing);
        for (final nombre in ['Fútbol', 'Tenis']) {
          final nodo = tester.getSemantics(find.bySemanticsLabel(nombre));
          expect(nodo.label, nombre);
          expect(nodo.flagsCollection.isButton, isFalse, reason: nombre);
        }

        await tester.tap(find.byType(TileDeporte).first);
        await tester.pumpAndSettle();
        expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets(
      'un deporte desconocido lleva el emoji 🏅 y el de fútbol ⚽ @RED-03-ASM-12',
      (tester) async {
        await _montarInicio(tester, catalogo: _catalogoConDesconocido);

        final tiles = tester
            .widgetList<TileDeporte>(find.byType(TileDeporte))
            .toList();
        expect(
          [for (final t in tiles) (t.nombre, t.emoji)],
          [('Fútbol', '⚽'), ('Rugby', '🏅')],
        );
        expect(tiles.last.imagen, fotoDeDeporte('Rugby'));
      },
    );

    testWidgets(
      'con más de una tanda de próximas el marcador dice 20+ @RED-03-ASM-13',
      (tester) async {
        await _montarInicio(
          tester,
          reservas: [
            for (var i = 1; i <= 20; i++)
              _reserva(
                id: _uuid(i),
                inicio: _delClub(12, 21).add(Duration(days: i)),
              ),
          ],
          siguiente: 'marcador-de-la-siguiente-tanda',
        );

        expect(_enElMarcador(find.text('20+')), findsOneWidget);
        expect(_colorDeCifra(tester, '20+'), _oscura.accentOnMedia);
      },
    );
  });

  group('tarjeta de reserva', () {
    testWidgets(
      'la tarjeta de reserva separa encabezado y detalle con el troquel @RED-03-S2',
      (tester) async {
        await _montarInicio(tester);
        await _expectTroquelEntreEncabezadoYDetalle(tester);

        await _montarMisReservas(tester, proximas: '[${_reserva()}]');
        await _expectTroquelEntreEncabezadoYDetalle(tester);
      },
    );

    testWidgets(
      'una reserva activa lleva el borde del acento y la cuenta regresiva @RED-03-S2',
      (tester) async {
        for (final (tema, p) in [
          (temaOscuro, Paleta.oscura),
          (temaClaro, Paleta.clara),
        ]) {
          await _montarInicio(
            tester,
            reservas: [_reserva(inicio: _delClub(14, 12))],
            tema: tema,
          );

          final borde = _enLaTarjeta(find.byKey(_claveBorde));
          expect(borde, findsOneWidget);
          expect(_colorDelBorde(tester, borde), p.accentBase);
          expect(tester.getSize(borde).width, 4);
          expect(
            tester.getTopLeft(borde).dx -
                tester.getTopLeft(find.byType(TarjetaReserva)).dx,
            inInclusiveRange(0, 2),
          );
          expect(_enLaTarjeta(find.text('FALTAN 2 DÍAS')), findsOneWidget);
        }
      },
    );

    testWidgets('la cuenta dice HOY, MAÑANA o FALTAN N DÍAS @RED-03-S2', (
      tester,
    ) async {
      for (final (inicio, cuenta) in [
        (_delClub(12, 21), 'HOY'),
        (_delClub(13, 12), 'MAÑANA'),
        (_delClub(14, 12), 'FALTAN 2 DÍAS'),
        (_delClub(19, 10), 'FALTAN 7 DÍAS'),
      ]) {
        await _montarInicio(tester, reservas: [_reserva(inicio: inicio)]);

        expect(_enLaTarjeta(find.text(cuenta)), findsOneWidget, reason: cuenta);
        for (final otra in [..._cuentas, 'FALTAN 7 DÍAS']) {
          if (otra != cuenta) {
            expect(find.text(otra), findsNothing, reason: '$cuenta sin $otra');
          }
        }
      }
    });

    testWidgets('una reserva cancelada no lleva borde ni cuenta @RED-03-S2', (
      tester,
    ) async {
      await _montarMisReservas(
        tester,
        historial:
            '[${_reserva(id: '00000000-0000-7000-8000-000000000001', estado: 'cancelada', inicio: _delClub(14, 12))}, '
            '${_reserva(id: '00000000-0000-7000-8000-000000000002', estado: 'anulada', motivo: 'lluvia', inicio: _delClub(14, 12))}, '
            '${_reserva(id: '00000000-0000-7000-8000-000000000003', estado: 'completada', inicio: _delClub(10, 12))}]',
        inicio: '/reservas?historial=1',
      );

      expect(find.byType(TarjetaReserva), findsNWidgets(3));
      expect(find.byKey(_claveBorde), findsNothing);
      _sinCuenta();
      expect(find.textContaining('FALTAN'), findsNothing);
      expect(find.byType(Troquel), findsNWidgets(3));
    });

    testWidgets('mis reservas no suma un marcador @RED-03-ASM-05', (
      tester,
    ) async {
      await _montarMisReservas(tester, proximas: '[${_reserva()}]');
      expect(find.byType(Troquel), findsOneWidget);
      expect(find.byType(Marcador), findsNothing);

      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();
      expect(find.byType(Marcador), findsNothing);
    });

    testWidgets('la cuenta mira el día del club y no la hora @RED-03-ASM-06', (
      tester,
    ) async {
      // 23:50 del 12 en el club: la reserva de las 00:30 del 13 es mañana, no hoy.
      await withClock(Clock.fixed(_delClub(12, 23, 50)), () async {
        await _montarInicio(
          tester,
          reservas: [_reserva(inicio: _delClub(13, 0, 30))],
        );
        expect(_enLaTarjeta(find.text('MAÑANA')), findsOneWidget);
        expect(find.text('HOY'), findsNothing);
      });

      // 00:10 del 12 en el club: la reserva de las 23:50 de ese día es hoy.
      await withClock(Clock.fixed(_delClub(12, 0, 10)), () async {
        await _montarInicio(
          tester,
          reservas: [_reserva(inicio: _delClub(12, 23, 50))],
        );
        expect(_enLaTarjeta(find.text('HOY')), findsOneWidget);
        expect(find.text('MAÑANA'), findsNothing);
      });
    });

    testWidgets(
      'la cuenta va en la próxima del inicio y no en Mis reservas @RED-03-ASM-09',
      (tester) async {
        final semantica = tester.ensureSemantics();
        for (final inicio in [
          _delClub(12, 21),
          _delClub(13, 12),
          _delClub(14, 12),
        ]) {
          await _montarMisReservas(
            tester,
            proximas: '[${_reserva(inicio: inicio)}]',
          );

          _sinCuenta();
          expect(find.bySemanticsLabel(RegExp('faltan')), findsNothing);
          expect(find.byType(Troquel), findsOneWidget);
          expect(find.byKey(_claveBorde), findsOneWidget);
          expect(
            _colorDelBorde(tester, find.byKey(_claveBorde)),
            _oscura.accentBase,
          );
        }

        await _montarInicio(
          tester,
          reservas: [_reserva(inicio: _delClub(14, 12))],
        );
        expect(find.text('FALTAN 2 DÍAS'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets(
      'una reserva activa resaltada conserva el contorno de foco y suma el borde @RED-03-ASM-10',
      (tester) async {
        await _montarMisReservas(
          tester,
          proximas:
              '[${_reserva(id: '00000000-0000-7000-8000-000000000001', inicio: _delClub(13, 10))}, '
              '${_reserva(id: '00000000-0000-7000-8000-000000000002', inicio: _delClub(14, 10))}]',
          inicio: '/reservas?reserva=00000000-0000-7000-8000-000000000002',
        );

        final comun = find.byType(TarjetaReserva).at(0);
        final resaltada = find.byType(TarjetaReserva).at(1);
        expect(_conContornoDeFoco(tester, resaltada), isTrue);
        expect(_conContornoDeFoco(tester, comun), isFalse);
        for (final tarjeta in [comun, resaltada]) {
          expect(
            find.descendant(of: tarjeta, matching: find.byKey(_claveBorde)),
            findsOneWidget,
          );
        }
      },
    );

    testWidgets(
      'el lector anuncia la cuenta al final de la tarjeta, «… faltan 2 días» @RED-03-ASM-11',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await _montarInicio(
          tester,
          reservas: [_reserva(inicio: _delClub(14, 12))],
        );

        final etiqueta = find.bySemanticsLabel(
          RegExp(r'^Fútbol 5, Sede Morón, .*, faltan 2 días$'),
        );
        expect(etiqueta, findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('FALTAN')), findsNothing);
        semantica.dispose();
      },
    );
  });

  group('mi perfil', () {
    Future<void> montarPerfil(WidgetTester tester, {bool oscuro = true}) =>
        montarUsuario(
          tester,
          inicio: '/perfil',
          oscuro: oscuro,
          api: apiRutas(rutasDeSedes()),
        );

    Finder enLaFicha(Finder hijo) =>
        find.descendant(of: find.byType(FichaSocio), matching: hijo);

    testWidgets('la cabecera de mi perfil es la ficha de socio @RED-03-S3', (
      tester,
    ) async {
      await montarPerfil(tester);

      expect(find.byType(FichaSocio), findsOneWidget);
      final ficha = tester.widget<FichaSocio>(find.byType(FichaSocio));
      expect(ficha.iniciales, 'NM');
      expect(ficha.nombre, 'Nahuel Mosse');
      expect(ficha.correo, 'nmosse@unimoron.edu.ar');
      expect(enLaFicha(find.text('NM')), findsOneWidget);
      expect(enLaFicha(find.text('Nahuel Mosse')), findsOneWidget);
      expect(enLaFicha(find.text('nmosse@unimoron.edu.ar')), findsOneWidget);
    });

    testWidgets(
      'la ficha de mi perfil dice MIEMBRO ACTIVO y no muestra marcador @RED-03-ASM-04',
      (tester) async {
        await montarPerfil(tester);

        final ficha = tester.widget<FichaSocio>(find.byType(FichaSocio));
        expect(ficha.numero, 'MIEMBRO ACTIVO');
        expect(ficha.estadisticas, isEmpty);
        expect(enLaFicha(find.text('MIEMBRO ACTIVO')), findsOneWidget);
        expect(enLaFicha(find.byType(Marcador)), findsNothing);
      },
    );

    testWidgets(
      'la ficha de mi perfil lleva la foto en los dos modos @RED-03-ASM-07',
      (tester) async {
        for (final oscuro in [true, false]) {
          await montarPerfil(tester, oscuro: oscuro);

          final ficha = tester.widget<FichaSocio>(find.byType(FichaSocio));
          expect(ficha.imagen, fotoDeDeporte('Futbol'), reason: '$oscuro');
          expect(enLaFicha(find.byType(Image)), findsOneWidget);
        }
      },
    );
  });

  group('sedes', () {
    testWidgets(
      'cada tarjeta de sede lleva el dorsal con sus canchas @RED-03-S4',
      (tester) async {
        await montarUsuario(
          tester,
          tamano: const Size(393, 1800),
          api: apiRutas(
            rutasDeSedes(
              sedes:
                  '[$sedeMoronConDeportes, $sedeHaedoSinCanchas, '
                  '${_sede('00000000-0000-7000-8000-000000000007', 'Sede Ituzaingó', 'Blas Parera 300', 12)}]',
            ),
          ),
        );

        final tarjetas = find.byType(TarjetaSede);
        expect(tarjetas, findsNWidgets(3));
        final dorsales = <String>[];
        for (var i = 0; i < 3; i++) {
          final tarjeta = tarjetas.at(i);
          final dorsal = find.descendant(
            of: tarjeta,
            matching: find.byType(DorsalGigante),
          );
          expect(dorsal, findsOneWidget);
          final canchas = tester.widget<TarjetaSede>(tarjeta).sede.canchas;
          final texto = canchas.toString().padLeft(2, '0');
          expect(tester.widget<DorsalGigante>(dorsal).texto, texto);
          final pintor = tester
              .widgetList<CustomPaint>(
                find.descendant(of: dorsal, matching: find.byType(CustomPaint)),
              )
              .map((c) => c.painter)
              .whereType<PintorDorsal>()
              .single;
          expect(pintor.texto, texto);
          dorsales.add(texto);
        }
        expect(dorsales, ['02', '00', '12']);
      },
    );
  });

  group('horarios', () {
    Future<void> abrirHorarios(WidgetTester tester, {String? grilla}) =>
        montarUsuario(
          tester,
          inicio: '/sedes/00000000-0000-7000-8000-000000000001/canchas/00000000-0000-7000-8000-000000000009',
          tamano: const Size(393, 2400),
          api: apiRutas(rutasDeSedes(grilla: grilla)),
        );

    String estadoDe(int hora) {
      final etiqueta = RegExp('^${hora.toString().padLeft(2, '0')} h ');
      return find.bySemanticsLabel(etiqueta).evaluate().isEmpty
          ? 'sin celda'
          : [
              for (final e in ['libre', 'ocupada', 'elegida'])
                if (find
                    .bySemanticsLabel('${hora.toString().padLeft(2, '0')} h $e')
                    .evaluate()
                    .isNotEmpty)
                  e,
            ].single;
    }

    testWidgets(
      'arriba de la grilla va la línea del día con el estado de cada franja @RED-03-S5',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await abrirHorarios(tester);

        expect(find.byType(LineaDelDia), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(LineaDelDia)).dy,
          lessThan(tester.getTopLeft(find.text('08:00 – 09:00')).dy),
        );
        const ocupadas = {9, 12, 16, 17, 21, 22};
        for (var h = 8; h < 23; h++) {
          final hora = h.toString().padLeft(2, '0');
          expect(find.byKey(ValueKey('franja-$hora')), findsOneWidget);
          expect(
            estadoDe(h),
            ocupadas.contains(h) ? 'ocupada' : 'libre',
            reason: '$hora h',
          );
        }
        expect(find.byKey(const ValueKey('franja-07')), findsNothing);
        expect(find.byKey(const ValueKey('franja-23')), findsNothing);
        semantica.dispose();
      },
    );

    testWidgets(
      'con dos horas cada hora es libre si una franja libre la cubre y la elegida marca sus dos horas @RED-03-ASM-08',
      (tester) async {
        final semantica = tester.ensureSemantics();
        String franja(int h, bool libre) =>
            '{"inicio": "${h.toString().padLeft(2, '0')}:00", '
            '"fin": "${(h + 2).toString().padLeft(2, '0')}:00", '
            '"disponible": $libre}';
        await abrirHorarios(
          tester,
          grilla:
              '{"fecha": "2026-11-12", "hoy": "2026-11-12", "abre": true, '
              '"franjas": [${franja(8, true)}, ${franja(9, false)}, '
              '${franja(10, false)}, ${franja(11, false)}, ${franja(12, true)}, '
              '${franja(13, false)}], "no_disponibles": 4}',
        );
        await tester.tap(find.bySemanticsLabel('Una hora más'));
        await tester.pumpAndSettle();

        // La hora 9 es libre por la franja de las 08:00, aunque la de las 09:00 no lo sea.
        expect(
          {for (var h = 8; h < 23; h++) h: estadoDe(h)},
          {
            8: 'libre',
            9: 'libre',
            10: 'ocupada',
            11: 'ocupada',
            12: 'libre',
            13: 'libre',
            for (var h = 14; h < 23; h++) h: 'ocupada',
          },
        );

        await tester.tap(find.bySemanticsLabel('12:00 – 14:00'));
        await tester.pumpAndSettle();

        expect(
          {for (var h = 8; h < 15; h++) h: estadoDe(h)},
          {
            8: 'libre',
            9: 'libre',
            10: 'ocupada',
            11: 'ocupada',
            12: 'elegida',
            13: 'elegida',
            14: 'ocupada',
          },
        );
        semantica.dispose();
      },
    );

    testWidgets(
      'con «No hay horarios disponibles» no va la línea del día @RED-03-ASM-08',
      (tester) async {
        await abrirHorarios(tester);
        expect(find.byType(LineaDelDia), findsOneWidget);

        for (final grilla in [
          grillaJson(abre: false),
          grillaJson(ocupadas: {for (var h = 8; h < 23; h++) h}),
        ]) {
          await abrirHorarios(tester, grilla: grilla);

          expect(find.text('No hay horarios disponibles'), findsOneWidget);
          expect(find.byType(LineaDelDia), findsNothing);
        }
      },
    );
  });

  group('login', () {
    testWidgets('la marca del login lleva el isotipo decorativo @RED-03-S6', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final sesion = Sesion(
        credenciales: CredencialesFalsas(),
        api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
      );
      final rutas = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => PantallaInicioSesion(
              sesion: sesion,
              pendiente: ReservaPendiente(),
            ),
          ),
        ],
      );
      addTearDown(rutas.dispose);
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp.router(theme: temaOscuro, routerConfig: rutas),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Isotipo), findsOneWidget);
      expect(tester.widget<Isotipo>(find.byType(Isotipo)).decorativo, isTrue);
      expect(
        tester.getTopLeft(find.byType(Isotipo)).dy,
        lessThan(tester.getTopLeft(find.text('BIENVENIDO A')).dy),
      );
      expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
      semantica.dispose();
    });
  });
}

Future<void> _expectTroquelEntreEncabezadoYDetalle(WidgetTester tester) async {
  final troquel = find.descendant(
    of: find.byType(TarjetaReserva),
    matching: find.byType(Troquel),
  );
  expect(troquel, findsOneWidget);
  expect(tester.widget<Troquel>(troquel).fondo, _oscura.bgBase);
  final y = tester.getTopLeft(troquel).dy;
  expect(
    tester.getTopLeft(find.text('Sede Morón · Av. Rivadavia 19850')).dy,
    lessThan(y),
  );
  expect(
    tester.getTopLeft(find.text('Moron_Rivadavia_19850_Futbol_F5_1')).dy,
    greaterThan(y),
  );
}
