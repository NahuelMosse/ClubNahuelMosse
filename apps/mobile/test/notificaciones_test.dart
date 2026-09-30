import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/notificaciones/centro.dart';
import 'package:clubnahuelmosse/notificaciones/notificacion.dart';
import 'package:clubnahuelmosse/notificaciones/notificaciones.dart';
import 'package:clubnahuelmosse/notificaciones/panel_avisos.dart';
import 'package:clubnahuelmosse/notificaciones/pantalla_notificaciones.dart';
import 'package:clubnahuelmosse/notificaciones/sistema.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

/// Las 20:00 del jueves 12 de noviembre, en la hora del club.
final ahoraClub = DateTime.utc(2026, 11, 12, 20);

String notif({
  required int id,
  required DateTime club,
  String tipo = 'recordatorio',
  String titulo = 'Tu reserva es en 1 hora',
  String cuerpo = 'Fútbol 5 · Sede Morón · 21:00 – 22:00',
  int? reservaId = 1,
  bool leida = false,
}) =>
    '{"id": $id, "tipo": "$tipo", "titulo": "$titulo", "cuerpo": "$cuerpo", '
    '"reserva_id": ${reservaId ?? 'null'}, '
    '"creada_en": "${club.add(const Duration(hours: 3)).toIso8601String()}", '
    '"leida": $leida}';

final recordatorio = notif(id: 3, club: DateTime.utc(2026, 11, 12, 19, 58));
final confirmacion = notif(
  id: 2,
  club: DateTime.utc(2026, 11, 12, 17),
  tipo: 'cancelacion_usuario',
  titulo: 'Reserva cancelada',
  cuerpo:
      'Vóley · Sede Ramos Mejía · Mié 11, 20:00. El horario quedó liberado.',
  leida: true,
);
final alerta = notif(
  id: 1,
  club: DateTime.utc(2026, 11, 11, 15),
  tipo: 'cancelacion_forzosa',
  titulo: 'El club anuló tu reserva',
  cuerpo: 'Hockey 7 · Sede Ramos Mejía · Vie 30, 19:00. Motivo: mantenimiento.',
  leida: true,
);

Map<String, Object?> cuerpoDe(http.Request pedido) =>
    jsonDecode(pedido.body) as Map<String, Object?>;

class SistemaFalso implements SistemaDeNotificaciones {
  SistemaFalso({this.concedido = true});

  bool concedido;
  int solicitudes = 0;

  @override
  String get plataforma => 'android';

  @override
  Future<bool> permitido() async => concedido;

  @override
  Future<bool> solicitarPermiso() async {
    solicitudes++;
    concedido = true;
    return true;
  }

  @override
  Future<String?> token() async => 'token-del-telefono';

  @override
  Stream<int?> get alLlegar => const Stream.empty();

  @override
  Stream<int?> get alTocar => const Stream.empty();

  @override
  Future<int?> abiertaPor() async => null;
}

/// La API de notificaciones, con lo que devuelve el centro y cada pedido anotado.
class ApiFalsa {
  List<String> avisos = [];
  int noLeidas = 0;
  bool caida = false;
  final pedidos = <http.Request>[];
  void Function(http.Request)? alPedir;

  ClienteApi get cliente => ClienteApi(
    'http://api.falsa',
    cliente: MockClient((pedido) async {
      pedidos.add(pedido);
      alPedir?.call(pedido);
      if (caida) throw http.ClientException('sin red');
      final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
        ('GET', '/notificaciones') => (
          200,
          '{"notificaciones": [${avisos.join(', ')}], "no_leidas": $noLeidas}',
        ),
        ('GET', '/yo') => (200, perfilJson()),
        ('GET', '/reservas') => (
          200,
          '{"reservas": [${reservaJson()}, ${reservaJson(id: 2, inicio: '2026-11-15T13:00:00+00:00', fin: '2026-11-15T14:00:00+00:00')}]}',
        ),
        ('GET', '/espacios/catalogo') => (200, catalogoJson),
        ('PUT', '/dispositivos') ||
        ('POST', '/dispositivos/baja') ||
        ('POST', '/notificaciones/leer-todas') => (204, ''),
        ('POST', final ruta) when ruta.endsWith('/leer') => (204, ''),
        _ => (404, '{}'),
      };
      return http.Response.bytes(
        utf8.encode(cuerpo),
        codigo,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  Iterable<http.Request> de(String metodo, String ruta) =>
      pedidos.where((p) => p.method == metodo && p.url.path == ruta);
}

/// Por defecto el teléfono está en las 21:00 del club del 12 de noviembre: lo que ya estaba sin
/// leer a las 19:58 no llegó mientras la app arrancaba.
CentroDeNotificaciones centroDe(
  ApiFalsa api,
  Sesion sesion, {
  SistemaDeNotificaciones? sistema,
  DateTime Function()? ahora,
}) => CentroDeNotificaciones(
  notificaciones: Notificaciones(api: api.cliente, sesion: sesion),
  sesion: sesion,
  sistema: sistema ?? SistemaFalso(),
  cada: Duration.zero,
  ahora: ahora ?? () => DateTime.utc(2026, 11, 13),
);

void main() {
  setUpAll(cargarFuentes);

  group('cuándo llegó y en qué día', () {
    final hoy = DateTime.utc(2026, 11, 12, 20);

    test('el rótulo del día es HOY, AYER o la fecha', () {
      expect(rotuloDeDia(DateTime.utc(2026, 11, 12, 0, 5), hoy), 'HOY');
      expect(rotuloDeDia(DateTime.utc(2026, 11, 11, 23, 59), hoy), 'AYER');
      expect(rotuloDeDia(DateTime.utc(2026, 11, 9, 9), hoy), '09/11');
    });

    test('cuándo llegó se cuenta desde ahora hasta ayer', () {
      expect(cuandoLlego(DateTime.utc(2026, 11, 12, 19, 59, 30), hoy), 'AHORA');
      expect(
        cuandoLlego(DateTime.utc(2026, 11, 12, 19, 58), hoy),
        'HACE 2 MIN',
      );
      expect(cuandoLlego(DateTime.utc(2026, 11, 12, 17), hoy), 'HACE 3 H');
      expect(cuandoLlego(DateTime.utc(2026, 11, 11, 15), hoy), 'AYER');
      expect(cuandoLlego(DateTime.utc(2026, 11, 3, 15), hoy), '03/11');
    });

    test('agrupa por día conservando de la más nueva a la más vieja', () {
      final lista = [
        for (final json in [recordatorio, confirmacion, alerta])
          Notificacion.desdeJson(jsonDecode(json))!,
      ];

      final grupos = agruparPorDia(lista, hoy);

      expect(grupos.map((g) => g.rotulo), ['HOY', 'AYER']);
      expect(grupos.first.notificaciones.map((n) => n.id), [3, 2]);
    });

    test('un tipo que la app no conoce no se lee', () {
      expect(
        Notificacion.desdeJson(
          jsonDecode(notif(id: 9, club: hoy, tipo: 'otra')),
        ),
        isNull,
      );
    });
  });

  group('el centro', () {
    Future<(ApiFalsa, CentroDeNotificaciones)> abrir(
      WidgetTester tester, {
      List<String> avisos = const [],
      int noLeidas = 0,
      bool permiso = true,
      Size tamano = const Size(393, 852),
      double escala = 1,
      bool oscuro = true,
      void Function(Notificacion)? alAbrir,
    }) async {
      final api = ApiFalsa()
        ..avisos = [...avisos]
        ..noLeidas = noLeidas;
      final sesion = SesionFalsa(perfilUsuario);
      final centro = centroDe(
        api,
        sesion,
        sistema: SistemaFalso(concedido: permiso),
      );
      await montar(
        tester,
        PantallaNotificaciones(
          centro: centro,
          sesion: sesion,
          ahora: () => ahoraClub,
          alAbrir: (_, n) => alAbrir?.call(n),
        ),
        tema: oscuro ? temaOscuro : temaClaro,
        tamano: tamano,
        escalaTexto: escala,
      );
      return (api, centro);
    }

    testWidgets('agrupa por día, marca las sin leer y respeta el orden', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrir(
        tester,
        avisos: [recordatorio, confirmacion, alerta],
        noLeidas: 1,
      );

      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('AYER'), findsOneWidget);
      expect(find.text('CLUBNAHUELMOSSE · HACE 2 MIN'), findsOneWidget);
      expect(find.text('CLUBNAHUELMOSSE · HACE 3 H'), findsOneWidget);
      expect(find.text('CLUBNAHUELMOSSE · AYER'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Tu reserva es en 1 hora. Fútbol 5 · Sede Morón · 21:00 – 22:00. '
          'HACE 2 MIN, sin leer',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('sin leer')), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Tu reserva es en 1 hora')).dy <
            tester.getTopLeft(find.text('Reserva cancelada')).dy,
        isTrue,
      );
      expect(
        tester.getTopLeft(find.text('Reserva cancelada')).dy <
            tester.getTopLeft(find.text('El club anuló tu reserva')).dy,
        isTrue,
      );
      semantica.dispose();
    });

    testWidgets('sin avisos y con permiso dice que todavía no hay ninguno', (
      tester,
    ) async {
      await abrir(tester);

      expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
      expect(
        find.text('Acá vas a ver los recordatorios de tus reservas.'),
        findsOneWidget,
      );
      expect(find.text('ACTIVAR NOTIFICACIONES'), findsNothing);
    });

    testWidgets(
      'sin permiso ofrece activarlas y al activarlas registra el teléfono con permiso',
      (tester) async {
        final (api, _) = await abrir(tester, permiso: false);
        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(
          find.text(
            'Activá los avisos para que te recordemos tus reservas una hora antes.',
          ),
          findsOneWidget,
        );
        final antes = cuerpoDe(api.de('PUT', '/dispositivos').last);
        expect(antes['permiso'], isFalse);

        await tester.tap(find.text('ACTIVAR NOTIFICACIONES'));
        await tester.pumpAndSettle();

        expect(find.text('Notificaciones desactivadas'), findsNothing);
        expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
        final despues = cuerpoDe(api.de('PUT', '/dispositivos').last);
        expect(despues, {
          'token': 'token-del-telefono',
          'plataforma': 'android',
          'permiso': true,
        });
      },
    );

    testWidgets(
      'sin permiso pero con avisos, los muestra debajo de la franja',
      (tester) async {
        await abrir(
          tester,
          avisos: [recordatorio],
          noLeidas: 1,
          permiso: false,
        );

        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      },
    );

    testWidgets('tocar un aviso lo marca leído y lo abre', (tester) async {
      Notificacion? abierta;
      final (api, _) = await abrir(
        tester,
        avisos: [recordatorio],
        noLeidas: 1,
        alAbrir: (n) => abierta = n,
      );

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(abierta?.reservaId, 1);
      expect(api.de('POST', '/notificaciones/3/leer'), hasLength(1));
    });

    testWidgets(
      'sin conexión avisa del error y al reintentar muestra la lista',
      (tester) async {
        final api = ApiFalsa()
          ..avisos = [recordatorio]
          ..noLeidas = 1
          ..caida = true;
        final sesion = SesionFalsa(perfilUsuario);
        await montar(
          tester,
          PantallaNotificaciones(
            centro: centroDe(api, sesion),
            sesion: sesion,
            ahora: () => ahoraClub,
            alAbrir: (_, _) {},
          ),
          tema: temaOscuro,
        );

        expect(find.text('Error de conexión'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
        api.caida = false;
        await tester.tap(find.text('REINTENTAR'));
        await tester.pumpAndSettle();

        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
      },
    );

    testWidgets(
      'si la lectura falla no muestra un centro vacío que quedó de antes',
      (tester) async {
        final api = ApiFalsa();
        final sesion = SesionFalsa(perfilUsuario);
        final centro = centroDe(api, sesion);
        await tester.runAsync(centro.cargar);
        api.caida = true;
        await montar(
          tester,
          PantallaNotificaciones(
            centro: centro,
            sesion: sesion,
            ahora: () => ahoraClub,
            alAbrir: (_, _) {},
          ),
          tema: temaOscuro,
        );

        expect(find.text('Error de conexión'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      },
    );

    for (final (nombre, oscuro) in [('oscuro', true), ('claro', false)]) {
      testWidgets(
        'con el texto al 200 % en 360 de ancho nada se recorta ($nombre)',
        (tester) async {
          await abrir(
            tester,
            avisos: [recordatorio, confirmacion, alerta],
            noLeidas: 1,
            tamano: const Size(360, 800),
            escala: 2,
            oscuro: oscuro,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
          expect(
            find.text('Fútbol 5 · Sede Morón · 21:00 – 22:00'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'las desactivadas con el texto al 200 % en 360 de ancho ($nombre)',
        (tester) async {
          await abrir(
            tester,
            permiso: false,
            tamano: const Size(360, 800),
            escala: 2,
            oscuro: oscuro,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Notificaciones desactivadas'), findsOneWidget);
          expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
        },
      );
    }
  });

  group('el panel con la app abierta', () {
    Future<(ApiFalsa, CentroDeNotificaciones, List<Notificacion>)> abrir(
      WidgetTester tester, {
      bool permiso = true,
      Size tamano = const Size(393, 852),
      double escala = 1,
    }) async {
      final api = ApiFalsa();
      final sesion = SesionFalsa(perfilUsuario);
      final centro = centroDe(
        api,
        sesion,
        sistema: SistemaFalso(concedido: permiso),
      );
      final abiertas = <Notificacion>[];
      await montar(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            PanelDeAvisos(
              centro: centro,
              ahora: () => ahoraClub,
              alAbrir: abiertas.add,
            ),
          ],
        ),
        tema: temaOscuro,
        tamano: tamano,
        escalaTexto: escala,
      );
      return (api, centro, abiertas);
    }

    Future<void> llega(
      WidgetTester tester,
      ApiFalsa api,
      CentroDeNotificaciones centro,
      List<String> avisos,
    ) async {
      api
        ..avisos = avisos
        ..noLeidas = avisos.length;
      await tester.runAsync(centro.cargar);
      await tester.pumpAndSettle();
    }

    testWidgets('lo que ya estaba sin leer al abrir la app no abre el panel', (
      tester,
    ) async {
      final api = ApiFalsa()
        ..avisos = [recordatorio]
        ..noLeidas = 1;
      final sesion = SesionFalsa(perfilUsuario);
      final centro = centroDe(api, sesion);
      await montar(
        tester,
        PanelDeAvisos(centro: centro, alAbrir: (_) {}),
        tema: temaOscuro,
      );

      expect(centro.noLeidas, 1);
      expect(find.text('MARCAR TODAS'), findsNothing);
    });

    testWidgets('un aviso que llega abre el panel sin salir de la pantalla', (
      tester,
    ) async {
      final (api, centro, _) = await abrir(tester);

      await llega(tester, api, centro, [recordatorio]);

      expect(find.text('NOTIFICACIONES'), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
      expect(find.text('la pantalla de abajo'), findsOneWidget);
    });

    testWidgets('«Marcar todas» las lee y cierra el panel', (tester) async {
      final (api, centro, _) = await abrir(tester);
      await llega(tester, api, centro, [recordatorio]);

      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(centro.noLeidas, 0);
      expect(api.de('POST', '/notificaciones/leer-todas'), hasLength(1));
    });

    testWidgets('tocar afuera cierra el panel sin marcar nada', (tester) async {
      final (api, centro, _) = await abrir(tester);
      await llega(tester, api, centro, [recordatorio]);

      await tester.tap(
        find.bySemanticsLabel('Cerrar las notificaciones'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(centro.noLeidas, 1);
      expect(api.de('POST', '/notificaciones/leer-todas'), isEmpty);
    });

    testWidgets('tocar un aviso lo abre', (tester) async {
      final (api, centro, abiertas) = await abrir(tester);
      await llega(tester, api, centro, [recordatorio]);

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(abiertas.map((n) => n.id), [3]);
    });

    testWidgets('sin permiso del sistema no abre el panel', (tester) async {
      final (api, centro, _) = await abrir(tester, permiso: false);

      await llega(tester, api, centro, [recordatorio]);

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(centro.noLeidas, 1);
    });

    for (final ancho in [360.0, 430.0]) {
      testWidgets(
        'con el texto al 200 % en ${ancho.toInt()} de ancho entra en pantalla',
        (tester) async {
          final (api, centro, _) = await abrir(
            tester,
            tamano: Size(ancho, 800),
            escala: 2,
          );

          await llega(tester, api, centro, [
            recordatorio,
            recordatorio.replaceFirst('"id": 3', '"id": 4'),
          ]);

          expect(tester.takeException(), isNull);
          expect(find.text('MARCAR TODAS'), findsOneWidget);
          expect(
            tester.getBottomRight(find.text('MARCAR TODAS')).dx,
            lessThanOrEqualTo(ancho),
          );
        },
      );
    }
  });

  group('cuándo abre el panel', () {
    Future<(ApiFalsa, CentroDeNotificaciones)> montarPanel(
      WidgetTester tester,
      List<String> avisos,
    ) async {
      final api = ApiFalsa()
        ..avisos = avisos
        ..noLeidas = avisos.length;
      final centro = centroDe(
        api,
        SesionFalsa(perfilUsuario),
        ahora: DateTime.now,
      );
      await montar(
        tester,
        Stack(
          children: [
            const Scaffold(body: SizedBox.expand()),
            PanelDeAvisos(centro: centro, alAbrir: (_) {}),
          ],
        ),
        tema: temaOscuro,
      );
      return (api, centro);
    }

    Future<void> llega(
      WidgetTester tester,
      ApiFalsa api,
      CentroDeNotificaciones centro,
      List<String> avisos,
    ) async {
      api
        ..avisos = avisos
        ..noLeidas = avisos.length;
      await tester.runAsync(centro.cargar);
      await tester.pumpAndSettle();
    }

    String reciente(int id) => notif(id: id, club: enDelClub(DateTime.now()));

    testWidgets('lo que llega mientras la app arranca abre el panel', (
      tester,
    ) async {
      await montarPanel(tester, [reciente(5)]);

      expect(find.text('MARCAR TODAS'), findsOneWidget);
    });

    testWidgets(
      'si se cerró el panel sin leer, lo que llega después no lo reabre',
      (tester) async {
        final (api, centro) = await montarPanel(tester, []);
        await llega(tester, api, centro, [reciente(5)]);
        expect(find.text('MARCAR TODAS'), findsOneWidget);

        await tester.tap(
          find.bySemanticsLabel('Cerrar las notificaciones'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await llega(tester, api, centro, [reciente(6), reciente(5)]);

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(centro.noLeidas, 2);
      },
    );

    testWidgets('después de leer todo, lo que llega abre el panel de nuevo', (
      tester,
    ) async {
      final (api, centro) = await montarPanel(tester, []);
      await llega(tester, api, centro, [reciente(5)]);
      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      await llega(tester, api, centro, [reciente(6)]);

      expect(find.text('MARCAR TODAS'), findsOneWidget);
    });
  });

  group('el teléfono y la sesión', () {
    testWidgets('registra el teléfono con el permiso que tiene', (
      tester,
    ) async {
      final api = ApiFalsa();
      centroDe(
        api,
        SesionFalsa(perfilUsuario),
        sistema: SistemaFalso(concedido: false),
      );
      await tester.pumpAndSettle();

      final pedido = cuerpoDe(api.de('PUT', '/dispositivos').single);
      expect(pedido['permiso'], isFalse);
      expect(pedido['token'], 'token-del-telefono');
    });

    testWidgets('un administrador no registra teléfono ni consulta el centro', (
      tester,
    ) async {
      final api = ApiFalsa();
      centroDe(api, SesionFalsa(perfilAdmin));
      await tester.pumpAndSettle();

      expect(api.pedidos, isEmpty);
    });

    testWidgets(
      'al cerrar la sesión da de baja el teléfono con la sesión que se cierra',
      (tester) async {
        final api = ApiFalsa();
        final credenciales = CredencialesFalsas();
        final sesion = Sesion(credenciales: credenciales, api: api.cliente);
        String? autorizacionDeLaBaja;
        api.alPedir = (p) {
          if (p.url.path == '/dispositivos/baja') {
            autorizacionDeLaBaja = p.headers['authorization'];
          }
        };
        final centro = centroDe(api, sesion);
        await tester.runAsync(() async {
          await sesion.iniciar('nahuel@correo.com', 'ClubNahuel1');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(api.de('PUT', '/dispositivos'), hasLength(1));

        await tester.runAsync(sesion.cerrar);
        await tester.pumpAndSettle();

        expect(api.de('POST', '/dispositivos/baja'), hasLength(1));
        expect(cuerpoDe(api.de('POST', '/dispositivos/baja').single), {
          'token': 'token-del-telefono',
        });
        // La baja va con la sesión que se cerró, tomada antes de cerrarla.
        expect(autorizacionDeLaBaja, 'Bearer token-falso');
        expect(credenciales.salidas, 1);
        expect(centro.lista, isEmpty);
      },
    );

    testWidgets(
      'si no se puede dar de baja el teléfono, la sesión se cierra igual',
      (tester) async {
        final api = ApiFalsa();
        final credenciales = CredencialesFalsas();
        final sesion = Sesion(credenciales: credenciales, api: api.cliente);
        centroDe(api, sesion);
        await tester.runAsync(() async {
          await sesion.iniciar('nahuel@correo.com', 'ClubNahuel1');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        api.caida = true;
        await tester.runAsync(sesion.cerrar);

        expect(credenciales.salidas, 1);
        expect(sesion.perfil, isNull);
      },
    );
  });

  group('la campana y Mis reservas', () {
    testWidgets(
      'la campana del Home cuenta las sin leer y abre el centro @supuesto:CU-24.1-SUP-10',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final api = ApiFalsa()
          ..avisos = [recordatorio, confirmacion]
          ..noLeidas = 2;
        await montarUsuario(
          tester,
          inicio: '/inicio',
          api: api.cliente,
          centro: (sesion) => centroDe(api, sesion),
        );

        expect(
          find.bySemanticsLabel('Notificaciones, 2 sin leer'),
          findsOneWidget,
        );
        expect(find.text('2'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Notificaciones, 2 sin leer'));
        await tester.pumpAndSettle();

        expect(find.text('Notificaciones'), findsOneWidget);
        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        semantica.dispose();
      },
    );

    testWidgets('sin avisos sin leer la campana no cuenta nada', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = ApiFalsa();
      await montarUsuario(
        tester,
        inicio: '/inicio',
        api: api.cliente,
        centro: (sesion) => centroDe(api, sesion),
      );

      expect(find.bySemanticsLabel('Notificaciones'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('sin centro el Home no tiene campana', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarUsuario(tester, inicio: '/inicio', api: ApiFalsa().cliente);

      expect(find.bySemanticsLabel(RegExp('^Notificaciones')), findsNothing);
      semantica.dispose();
    });

    testWidgets(
      'un administrador no llega al centro @supuesto:CU-24.1-SUP-10',
      (tester) async {
        await montarAdmin(
          tester,
          inicio: '/notificaciones',
          api: ApiFalsa().cliente,
        );

        expect(find.text('Notificaciones'), findsNothing);
        expect(find.text('PANEL ADMIN'), findsOneWidget);
      },
    );

    testWidgets('tocar un aviso abre Mis reservas con esa reserva resaltada', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = ApiFalsa()
        ..avisos = [
          recordatorio.replaceFirst('"reserva_id": 1', '"reserva_id": 2'),
        ]
        ..noLeidas = 1;
      await montarUsuario(
        tester,
        inicio: '/notificaciones',
        api: api.cliente,
        centro: (sesion) => centroDe(api, sesion),
      );

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(find.text('Mis reservas'), findsOneWidget);
      bool resaltada(String horario) => tester
          .getSemantics(
            find.bySemanticsLabel(RegExp('^Fútbol 5, Sede Morón, .*$horario')),
          )
          .flagsCollection
          .isSelected;
      expect(resaltada('10:00 – 11:00'), isTrue);
      expect(resaltada('21:00 – 22:00'), isFalse);
      semantica.dispose();
    });

    testWidgets('sin reserva en el aviso abre Mis reservas sin resaltar nada', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = ApiFalsa();
      await montarUsuario(tester, inicio: '/reservas', api: api.cliente);

      expect(
        tester
            .getSemantics(
              find.bySemanticsLabel(
                RegExp('^Fútbol 5, Sede Morón, .*21:00 – 22:00'),
              ),
            )
            .flagsCollection
            .isSelected,
        isFalse,
      );
      semantica.dispose();
    });
  });
}
