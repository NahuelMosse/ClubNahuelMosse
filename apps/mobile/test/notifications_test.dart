import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/domain/app_notification.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'my_bookings_test.dart' show bookingJson;
import 'support/admin.dart';
import 'support/mount.dart';
import 'support/user.dart';

/// Las 20:00 del jueves 12 de noviembre, en la hora del club.
final noticesNow = DateTime.utc(2026, 11, 12, 20);

String noticeJson({
  required String id,
  required DateTime club,
  String kind = 'reminder',
  String title = 'Tu reserva es en 1 hora',
  String body = 'Fútbol 5 · Sede Morón · 21:00 – 22:00',
  String? bookingId = '00000000-0000-7000-8000-000000000001',
  bool read = false,
}) =>
    '{"id": "$id", "kind": "$kind", "title": "$title", "body": "$body", '
    '"booking_id": ${bookingId == null ? 'null' : '"$bookingId"'}, '
    '"created_at": "${club.add(const Duration(hours: 3)).toIso8601String()}", '
    '"read": $read}';

final reminderNotice = noticeJson(
  id: '00000000-0000-7000-8000-000000000003',
  club: DateTime.utc(2026, 11, 12, 19, 58),
);
final confirmationNotice = noticeJson(
  id: '00000000-0000-7000-8000-000000000002',
  club: DateTime.utc(2026, 11, 12, 17),
  kind: 'user_cancellation',
  title: 'Reserva cancelada',
  body:
      'Vóley · Sede Ramos Mejía · Mié 11, 20:00. El horario quedó liberado.',
  read: true,
);
final alertNotice = noticeJson(
  id: '00000000-0000-7000-8000-000000000001',
  club: DateTime.utc(2026, 11, 11, 15),
  kind: 'forced_cancellation',
  title: 'El club anuló tu reserva',
  body: 'Hockey 7 · Sede Ramos Mejía · Vie 30, 19:00. Motivo: mantenimiento.',
  read: true,
);

Map<String, Object?> bodyOf(http.Request pedido) =>
    jsonDecode(pedido.body) as Map<String, Object?>;

class FakeSystem implements NotificationSystem {
  FakeSystem({this.granted = true});

  bool granted;
  int requests = 0;
  int olvidos = 0;

  @override
  String get platform => 'android';

  @override
  Future<bool> isAllowed() async => granted;

  @override
  Future<bool> wasAsked() async => true;

  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = true;
    return true;
  }

  @override
  Future<String?> token() async => 'token-del-telefono';

  @override
  Future<void> forgetToken() async => olvidos++;

  @override
  Stream<void> get onArrive => const Stream.empty();

  @override
  Stream<NoticeTapped> get onTap => const Stream.empty();

  @override
  Future<NoticeTapped?> openedBy() async => null;
}

/// Un sistema cuyo permiso tarda lo que el test decida en contestar.
class SlowSystem extends FakeSystem {
  final respuesta = Completer<bool>();

  @override
  Future<bool> isAllowed() => respuesta.future;
}

/// Firebase con un cierre de sesión que tarda, como en un teléfono de verdad.
class SlowCredentials extends FakeCredentials {
  SlowCredentials({this.tarda = const Duration(milliseconds: 100)});

  final Duration tarda;

  /// Mientras sea `true`, el token nunca llega.
  bool sinToken = false;

  @override
  Future<String?> token() =>
      sinToken ? Completer<String?>().future : super.token();

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(tarda);
    await super.signOut();
  }
}

/// La API de notificaciones, con lo que devuelve el centro y cada pedido anotado.
class FakeApi {
  List<String> notices = [];
  int unread = 0;
  bool down = false;
  final requests = <http.Request>[];
  void Function(http.Request)? onRequest;

  ApiClient get client => ApiClient(
    'http://api.falsa',
    cliente: MockClient((pedido) async {
      requests.add(pedido);
      onRequest?.call(pedido);
      if (down) throw http.ClientException('sin red');
      final (codigo, cuerpo) = switch ((pedido.method, pedido.url.path)) {
        ('GET', '/notifications') => (
          200,
          '{"notifications": [${notices.join(', ')}], "unread": $unread}',
        ),
        ('GET', '/me') => (200, profileJson()),
        ('DELETE', '/me') => (204, ''),
        ('GET', '/bookings') => (
          200,
          '{"bookings": [${bookingJson()}, ${bookingJson(id: '00000000-0000-7000-8000-000000000002', start: '2026-11-15T13:00:00+00:00', end: '2026-11-15T14:00:00+00:00')}]}',
        ),
        ('GET', '/spaces/catalog') => (200, catalogJson),
        ('GET', '/venues') => (200, '{"venues": []}'),
        ('PUT', '/devices') ||
        ('POST', '/devices/unregister') ||
        ('POST', '/notifications/read-all') => (204, ''),
        ('POST', final ruta) when ruta.endsWith('/read') => (204, ''),
        _ => (404, '{}'),
      };
      return http.Response.bytes(
        utf8.encode(cuerpo),
        codigo,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  Iterable<http.Request> of(String metodo, String ruta) =>
      requests.where((p) => p.method == metodo && p.url.path == ruta);
}

/// Por defecto el teléfono está en las 21:00 del club del 12 de noviembre: lo que ya estaba sin
/// leer a las 19:58 no llegó mientras la app arrancaba.
NotificationCenter centerOf(
  FakeApi api,
  Session session, {
  NotificationSystem? system,
  DateTime Function()? now,
}) => NotificationCenter(
  notifications: NotificationsRepository(api: api.client, session: session),
  session: session,
  system: system ?? FakeSystem(),
  every: Duration.zero,
  now: now ?? () => DateTime.utc(2026, 11, 13),
);

void main() {
  setUpAll(loadFonts);

  group('cuándo llegó y en qué día', () {
    final hoy = DateTime.utc(2026, 11, 12, 20);

    test('el rótulo del día es HOY, AYER o la fecha', () {
      expect(dayLabel(DateTime.utc(2026, 11, 12, 0, 5), hoy), 'HOY');
      expect(dayLabel(DateTime.utc(2026, 11, 11, 23, 59), hoy), 'AYER');
      expect(dayLabel(DateTime.utc(2026, 11, 9, 9), hoy), '09/11');
    });

    test('cuándo llegó se cuenta desde ahora hasta ayer', () {
      expect(
        arrivedLabel(DateTime.utc(2026, 11, 12, 19, 59, 30), hoy),
        'AHORA',
      );
      expect(
        arrivedLabel(DateTime.utc(2026, 11, 12, 19, 58), hoy),
        'HACE 2 MIN',
      );
      expect(arrivedLabel(DateTime.utc(2026, 11, 12, 17), hoy), 'HACE 3 H');
      expect(arrivedLabel(DateTime.utc(2026, 11, 11, 15), hoy), 'AYER');
      expect(arrivedLabel(DateTime.utc(2026, 11, 3, 15), hoy), '03/11');
    });

    test('agrupa por día conservando de la más nueva a la más vieja', () {
      final lista = [
        for (final json in [reminderNotice, confirmationNotice, alertNotice])
          AppNotification.fromJson(jsonDecode(json))!,
      ];

      final grupos = groupByDay(lista, hoy);

      expect(grupos.map((g) => g.label), ['HOY', 'AYER']);
      expect(grupos.first.notifications.map((n) => n.id), [
        '00000000-0000-7000-8000-000000000003',
        '00000000-0000-7000-8000-000000000002',
      ]);
    });

    test(
      'cada aviso lleva a la pestaña de Mis reservas que le corresponde',
      () {
        expect(
          noticeRoute(
            NotificationKind.reminder,
            '00000000-0000-7000-8000-000000000007',
          ),
          '/reservas?reserva=00000000-0000-7000-8000-000000000007',
        );
        expect(
          noticeRoute(
            NotificationKind.forcedCancellation,
            '00000000-0000-7000-8000-000000000007',
          ),
          '/reservas?historial=1&reserva=00000000-0000-7000-8000-000000000007',
        );
        expect(
          noticeRoute(
            NotificationKind.userCancellation,
            '00000000-0000-7000-8000-000000000007',
          ),
          '/reservas?historial=1&reserva=00000000-0000-7000-8000-000000000007',
        );
        expect(noticeRoute(NotificationKind.reminder, null), '/reservas');
        expect(noticeRoute(null, null), '/reservas');
      },
    );

    test('un tipo que la app no conoce no se lee', () {
      expect(
        AppNotification.fromJson(
          jsonDecode(
            noticeJson(
              id: '00000000-0000-7000-8000-000000000009',
              club: hoy,
              kind: 'otra',
            ),
          ),
        ),
        isNull,
      );
    });
  });

  group('el centro', () {
    Future<(FakeApi, NotificationCenter)> abrir(
      WidgetTester tester, {
      List<String> notices = const [],
      int unread = 0,
      bool permiso = true,
      Size tamano = const Size(393, 852),
      double escala = 1,
      bool oscuro = true,
      void Function(AppNotification)? alAbrir,
    }) async {
      final api = FakeApi()
        ..notices = [...notices]
        ..unread = unread;
      final sesion = FakeSession(userProfile);
      final centro = centerOf(
        api,
        sesion,
        system: FakeSystem(granted: permiso),
      );
      await mountScreen(
        tester,
        NotificationsScreen(
          center: centro,
          session: sesion,
          now: () => noticesNow,
          onOpen: (_, n) => alAbrir?.call(n),
        ),
        theme: oscuro ? darkTheme : lightTheme,
        size: tamano,
        textScale: escala,
      );
      return (api, centro);
    }

    testWidgets('agrupa por día, marca las sin leer y respeta el orden', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await abrir(
        tester,
        notices: [reminderNotice, confirmationNotice, alertNotice],
        unread: 1,
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
        final antes = bodyOf(api.of('PUT', '/devices').last);
        expect(antes['permission_granted'], isFalse);

        await tester.tap(find.text('ACTIVAR NOTIFICACIONES'));
        await tester.pumpAndSettle();

        expect(find.text('Notificaciones desactivadas'), findsNothing);
        expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
        final despues = bodyOf(api.of('PUT', '/devices').last);
        expect(despues, {
          'token': 'token-del-telefono',
          'platform': 'android',
          'permission_granted': true,
        });
      },
    );

    testWidgets(
      'sin permiso pero con avisos, los muestra debajo de la franja',
      (tester) async {
        await abrir(
          tester,
          notices: [reminderNotice],
          unread: 1,
          permiso: false,
        );

        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      },
    );

    testWidgets('tocar un aviso lo marca leído y lo abre', (tester) async {
      AppNotification? abierta;
      final (api, _) = await abrir(
        tester,
        notices: [reminderNotice],
        unread: 1,
        alAbrir: (n) => abierta = n,
      );

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(abierta?.bookingId, '00000000-0000-7000-8000-000000000001');
      expect(
        api.of(
          'POST',
          '/notifications/00000000-0000-7000-8000-000000000003/read',
        ),
        hasLength(1),
      );
    });

    testWidgets(
      'sin conexión avisa del error y al reintentar muestra la lista',
      (tester) async {
        final api = FakeApi()
          ..notices = [reminderNotice]
          ..unread = 1
          ..down = true;
        final sesion = FakeSession(userProfile);
        await mountScreen(
          tester,
          NotificationsScreen(
            center: centerOf(api, sesion),
            session: sesion,
            now: () => noticesNow,
            onOpen: (_, _) {},
          ),
          theme: darkTheme,
        );

        expect(find.text('Error de conexión'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
        api.down = false;
        await tester.tap(find.text('REINTENTAR'));
        await tester.pumpAndSettle();

        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
      },
    );

    testWidgets(
      'si la lectura falla no muestra un centro vacío que quedó de antes',
      (tester) async {
        final api = FakeApi();
        final sesion = FakeSession(userProfile);
        final centro = centerOf(api, sesion);
        await tester.runAsync(centro.load);
        api.down = true;
        await mountScreen(
          tester,
          NotificationsScreen(
            center: centro,
            session: sesion,
            now: () => noticesNow,
            onOpen: (_, _) {},
          ),
          theme: darkTheme,
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
            notices: [reminderNotice, confirmationNotice, alertNotice],
            unread: 1,
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
    Future<(FakeApi, NotificationCenter, List<AppNotification>)> abrir(
      WidgetTester tester, {
      bool permiso = true,
      Size tamano = const Size(393, 852),
      double escala = 1,
    }) async {
      final api = FakeApi();
      final sesion = FakeSession(userProfile);
      final centro = centerOf(
        api,
        sesion,
        system: FakeSystem(granted: permiso),
      );
      final abiertas = <AppNotification>[];
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(
              center: centro,
              now: () => noticesNow,
              onOpen: abiertas.add,
            ),
          ],
        ),
        theme: darkTheme,
        size: tamano,
        textScale: escala,
      );
      return (api, centro, abiertas);
    }

    Future<void> llega(
      WidgetTester tester,
      FakeApi api,
      NotificationCenter centro,
      List<String> notices,
    ) async {
      api
        ..notices = notices
        ..unread = notices.length;
      await tester.runAsync(centro.load);
      await tester.pumpAndSettle();
    }

    testWidgets('lo que ya estaba sin leer al abrir la app no abre el panel', (
      tester,
    ) async {
      final api = FakeApi()
        ..notices = [reminderNotice]
        ..unread = 1;
      final sesion = FakeSession(userProfile);
      final centro = centerOf(api, sesion);
      await mountScreen(
        tester,
        NoticePanel(center: centro, onOpen: (_) {}),
        theme: darkTheme,
      );

      expect(centro.unread, 1);
      expect(find.text('MARCAR TODAS'), findsNothing);
    });

    testWidgets('un aviso que llega abre el panel sin salir de la pantalla', (
      tester,
    ) async {
      final (api, centro, _) = await abrir(tester);

      await llega(tester, api, centro, [reminderNotice]);

      expect(find.text('NOTIFICACIONES'), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
      expect(find.text('la pantalla de abajo'), findsOneWidget);
    });

    testWidgets('«Marcar todas» las lee y cierra el panel', (tester) async {
      final (api, centro, _) = await abrir(tester);
      await llega(tester, api, centro, [reminderNotice]);

      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(centro.unread, 0);
      expect(api.of('POST', '/notifications/read-all'), hasLength(1));
    });

    testWidgets('tocar afuera cierra el panel sin marcar nada', (tester) async {
      final (api, centro, _) = await abrir(tester);
      await llega(tester, api, centro, [reminderNotice]);

      await tester.tap(
        find.bySemanticsLabel('Cerrar las notificaciones'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(centro.unread, 1);
      expect(api.of('POST', '/notifications/read-all'), isEmpty);
    });

    testWidgets('tocar un aviso lo abre', (tester) async {
      final (api, centro, abiertas) = await abrir(tester);
      await llega(tester, api, centro, [reminderNotice]);

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(abiertas.map((n) => n.id), [
        '00000000-0000-7000-8000-000000000003',
      ]);
    });

    testWidgets('sin permiso del sistema no abre el panel', (tester) async {
      final (api, centro, _) = await abrir(tester, permiso: false);

      await llega(tester, api, centro, [reminderNotice]);

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(centro.unread, 1);
    });

    testWidgets(
      'el atrás del sistema cierra el panel sin marcar nada ni tocar lo de abajo',
      (tester) async {
        final (api, centro, _) = await abrir(tester);
        await llega(tester, api, centro, [reminderNotice]);
        expect(find.text('MARCAR TODAS'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(centro.unread, 1);
        expect(find.text('la pantalla de abajo'), findsOneWidget);
      },
    );

    testWidgets(
      'con el panel abierto el lector de pantalla no llega a lo de abajo y lo anuncia',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final (api, centro, _) = await abrir(tester);
        List<String> etiquetas() => [
          for (final nodo in tester.semantics.simulatedAccessibilityTraversal())
            nodo.label,
        ];
        expect(etiquetas(), contains('la pantalla de abajo'));

        await llega(tester, api, centro, [reminderNotice]);

        expect(etiquetas(), isNot(contains('la pantalla de abajo')));
        expect(etiquetas(), contains('MARCAR TODAS'));
        expect(
          tester
              .getSemantics(find.text('NOTIFICACIONES'))
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(etiquetas(), contains('la pantalla de abajo'));
        semantica.dispose();
      },
    );

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
            reminderNotice,
            reminderNotice.replaceFirst(
              '"id": "00000000-0000-7000-8000-000000000003"',
              '"id": "00000000-0000-7000-8000-000000000004"',
            ),
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
    Future<(FakeApi, NotificationCenter)> montarPanel(
      WidgetTester tester,
      List<String> notices,
    ) async {
      final api = FakeApi()
        ..notices = notices
        ..unread = notices.length;
      final centro = centerOf(
        api,
        FakeSession(userProfile),
        now: DateTime.now,
      );
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: SizedBox.expand()),
            NoticePanel(center: centro, onOpen: (_) {}),
          ],
        ),
        theme: darkTheme,
      );
      return (api, centro);
    }

    Future<void> llega(
      WidgetTester tester,
      FakeApi api,
      NotificationCenter centro,
      List<String> notices,
    ) async {
      api
        ..notices = notices
        ..unread = notices.length;
      await tester.runAsync(centro.load);
      await tester.pumpAndSettle();
    }

    String reciente(String id) =>
        noticeJson(id: id, club: inClubTime(DateTime.now()));

    testWidgets('lo que llega mientras la app arranca abre el panel', (
      tester,
    ) async {
      await montarPanel(tester, [
        reciente('00000000-0000-7000-8000-000000000005'),
      ]);

      expect(find.text('MARCAR TODAS'), findsOneWidget);
    });

    testWidgets(
      'si se cerró el panel sin leer, lo que llega después no lo reabre',
      (tester) async {
        final (api, centro) = await montarPanel(tester, []);
        await llega(tester, api, centro, [
          reciente('00000000-0000-7000-8000-000000000005'),
        ]);
        expect(find.text('MARCAR TODAS'), findsOneWidget);

        await tester.tap(
          find.bySemanticsLabel('Cerrar las notificaciones'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await llega(tester, api, centro, [
          reciente('00000000-0000-7000-8000-000000000006'),
          reciente('00000000-0000-7000-8000-000000000005'),
        ]);

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(centro.unread, 2);
      },
    );

    testWidgets('después de leer todo, lo que llega abre el panel de nuevo', (
      tester,
    ) async {
      final (api, centro) = await montarPanel(tester, []);
      await llega(tester, api, centro, [
        reciente('00000000-0000-7000-8000-000000000005'),
      ]);
      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      await llega(tester, api, centro, [
        reciente('00000000-0000-7000-8000-000000000006'),
      ]);

      expect(find.text('MARCAR TODAS'), findsOneWidget);
    });
  });

  group('salir de la sesión', () {
    testWidgets('cerrar borra el token del teléfono', (tester) async {
      final api = FakeApi();
      final sistema = FakeSystem();
      final sesion = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: api.client,
        ),
      );
      centerOf(api, sesion, system: sistema);
      await tester.runAsync(() async {
        await sesion.signIn('nahuel@correo.com', 'ClubNahuel1');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await sesion.close();
      });

      expect(sistema.olvidos, 1);
    });

    testWidgets('una sesión que ya no vale también borra el token', (
      tester,
    ) async {
      final api = FakeApi();
      final sistema = FakeSystem();
      final credenciales = FakeCredentials(withAccount: true)
        ..tokenFails = true;
      final sesion = Session(
        repository: SessionRepository(
          credentials: credenciales,
          api: api.client,
        ),
      );
      centerOf(api, sesion, system: sistema);

      final perfil = await tester.runAsync(sesion.resume);

      expect(perfil, isNull);
      expect(credenciales.signOuts, 1);
      expect(sistema.olvidos, 1);
    });

    testWidgets('si falla el perfil después de entrar, también', (
      tester,
    ) async {
      final api = FakeApi();
      final sistema = FakeSystem();
      final sesion = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: ApiClient(
            'http://api.falsa',
            cliente: MockClient((_) async => http.Response('{}', 500)),
          ),
        ),
      );
      centerOf(api, sesion, system: sistema);

      await tester.runAsync(() async {
        await expectLater(
          sesion.signIn('nahuel@correo.com', 'ClubNahuel1'),
          throwsA(isA<ErrorDelServidor>()),
        );
      });

      expect(sistema.olvidos, 1);
    });

    testWidgets('dar de baja la cuenta borra el token', (tester) async {
      final api = FakeApi();
      final sistema = FakeSystem();
      final sesion = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: api.client,
        ),
      );
      centerOf(api, sesion, system: sistema);
      await tester.runAsync(() async {
        await sesion.signIn('nahuel@correo.com', 'ClubNahuel1');
        await sesion.deactivate();
      });

      expect(sistema.olvidos, 1);
    });

    testWidgets('sin nada que avisar, cerrar no espera el token', (
      tester,
    ) async {
      final credenciales = SlowCredentials(tarda: Duration.zero);
      final sesion = Session(
        repository: SessionRepository(
          credentials: credenciales,
          api: FakeApi().client,
        ),
      );
      await tester.runAsync(
        () => sesion.signIn('nahuel@correo.com', 'ClubNahuel1'),
      );
      credenciales.sinToken = true;

      await tester.runAsync(sesion.close);

      expect(credenciales.signOuts, 1);
    });

    testWidgets(
      'con el token colgado, cerrar espera dos segundos y sale igual',
      (tester) async {
        final credenciales = SlowCredentials(tarda: Duration.zero);
        final sesion = Session(
          repository: SessionRepository(
            credentials: credenciales,
            api: FakeApi().client,
          ),
        );
        sesion.onClose.add((_) async => fail('no había token que dar'));
        await tester.runAsync(
          () => sesion.signIn('nahuel@correo.com', 'ClubNahuel1'),
        );
        credenciales.sinToken = true;
        var cerro = false;

        unawaited(sesion.close().then((_) => cerro = true));
        await tester.pump(const Duration(seconds: 1));
        expect(cerro, isFalse);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(cerro, isTrue);
        expect(credenciales.signOuts, 1);
      },
    );

    testWidgets(
      'si la baja falla antes de que termine de salir, no queda un error sin atrapar',
      (tester) async {
        final credenciales = SlowCredentials();
        final sesion = Session(
          repository: SessionRepository(
            credentials: credenciales,
            api: FakeApi().client,
          ),
        );
        sesion.onClose.add(
          (_) => Future<void>.error(StateError('la API se cayó')),
        );
        await tester.runAsync(
          () => sesion.signIn('nahuel@correo.com', 'ClubNahuel1'),
        );

        await tester.runAsync(sesion.close);

        expect(tester.takeException(), isNull);
        expect(credenciales.signOuts, 1);
        expect(sesion.profile, isNull);
      },
    );
  });

  group('la consulta periódica', () {
    int lecturas(FakeApi api) => api.of('GET', '/notifications').length;

    testWidgets('un centro liberado mientras arrancaba no deja un reloj vivo', (
      tester,
    ) async {
      final api = FakeApi();
      final sistema = SlowSystem();
      final centro = NotificationCenter(
        notifications: NotificationsRepository(
          api: api.client,
          session: FakeSession(userProfile),
        ),
        session: FakeSession(userProfile),
        system: sistema,
        every: const Duration(seconds: 5),
      );

      centro.dispose();
      sistema.respuesta.complete(true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(seconds: 30));

      expect(lecturas(api), 0);
    });

    testWidgets('en segundo plano no consulta y al volver lee enseguida', (
      tester,
    ) async {
      final api = FakeApi();
      final centro = NotificationCenter(
        notifications: NotificationsRepository(
          api: api.client,
          session: FakeSession(userProfile),
        ),
        session: FakeSession(userProfile),
        system: FakeSystem(),
        every: const Duration(seconds: 10),
      );
      await tester.pump(const Duration(seconds: 1));
      final alArrancar = lecturas(api);
      await tester.pump(const Duration(seconds: 25));
      final conLaAppAbierta = lecturas(api);
      expect(conLaAppAbierta, greaterThan(alArrancar));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump(const Duration(seconds: 60));
      expect(lecturas(api), conLaAppAbierta);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(lecturas(api), conLaAppAbierta + 1);

      centro.dispose();
      await tester.pump();
    });
  });

  group('el teléfono y la sesión', () {
    testWidgets('registra el teléfono con el permiso que tiene', (
      tester,
    ) async {
      final api = FakeApi();
      centerOf(
        api,
        FakeSession(userProfile),
        system: FakeSystem(granted: false),
      );
      await tester.pumpAndSettle();

      final pedido = bodyOf(api.of('PUT', '/devices').single);
      expect(pedido['permission_granted'], isFalse);
      expect(pedido['token'], 'token-del-telefono');
    });

    testWidgets(
      'si se libera con un pedido en camino, al terminar no avisa a nadie',
      (tester) async {
        final api = FakeApi();
        final centro = centerOf(api, FakeSession(userProfile));

        centro.dispose();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('un administrador no registra teléfono ni consulta el centro', (
      tester,
    ) async {
      final api = FakeApi();
      centerOf(api, FakeSession(adminProfile));
      await tester.pumpAndSettle();

      expect(api.requests, isEmpty);
    });

    testWidgets(
      'al cerrar la sesión da de baja el teléfono con la sesión que se cierra',
      (tester) async {
        final api = FakeApi();
        final credenciales = FakeCredentials();
        final sesion = Session(
          repository: SessionRepository(
            credentials: credenciales,
            api: api.client,
          ),
        );
        String? autorizacionDeLaBaja;
        api.onRequest = (p) {
          if (p.url.path == '/devices/unregister') {
            autorizacionDeLaBaja = p.headers['authorization'];
          }
        };
        final centro = centerOf(api, sesion);
        await tester.runAsync(() async {
          await sesion.signIn('nahuel@correo.com', 'ClubNahuel1');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(api.of('PUT', '/devices'), hasLength(1));

        await tester.runAsync(sesion.close);
        await tester.pumpAndSettle();

        expect(api.of('POST', '/devices/unregister'), hasLength(1));
        expect(bodyOf(api.of('POST', '/devices/unregister').single), {
          'token': 'token-del-telefono',
        });
        // La baja va con la sesión que se cerró, tomada antes de cerrarla.
        expect(autorizacionDeLaBaja, 'Bearer token-falso');
        expect(credenciales.signOuts, 1);
        expect(centro.list, isEmpty);
      },
    );

    testWidgets(
      'si no se puede dar de baja el teléfono, la sesión se cierra igual',
      (tester) async {
        final api = FakeApi();
        final credenciales = FakeCredentials();
        final sesion = Session(
          repository: SessionRepository(
            credentials: credenciales,
            api: api.client,
          ),
        );
        centerOf(api, sesion);
        await tester.runAsync(() async {
          await sesion.signIn('nahuel@correo.com', 'ClubNahuel1');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        api.down = true;
        await tester.runAsync(sesion.close);

        expect(credenciales.signOuts, 1);
        expect(sesion.profile, isNull);
      },
    );
  });

  group('la campana y Mis reservas', () {
    testWidgets(
      'la campana del Home cuenta las sin leer y abre el centro @supuesto:CU-24.1-SUP-10',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final api = FakeApi()
          ..notices = [reminderNotice, confirmationNotice]
          ..unread = 2;
        await mountUser(
          tester,
          start: '/inicio',
          api: api.client,
          center: (sesion) => centerOf(api, sesion),
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
      final api = FakeApi();
      await mountUser(
        tester,
        start: '/inicio',
        api: api.client,
        center: (sesion) => centerOf(api, sesion),
      );

      expect(find.bySemanticsLabel('Notificaciones'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('sin centro el Home no tiene campana', (tester) async {
      final semantica = tester.ensureSemantics();
      await mountUser(tester, start: '/inicio', api: FakeApi().client);

      expect(find.bySemanticsLabel(RegExp('^Notificaciones')), findsNothing);
      semantica.dispose();
    });

    testWidgets(
      'un administrador no llega al centro @supuesto:CU-24.1-SUP-10',
      (tester) async {
        await mountAdmin(
          tester,
          start: '/notificaciones',
          api: FakeApi().client,
        );

        expect(find.text('Notificaciones'), findsNothing);
        expect(find.text('PANEL ADMIN'), findsOneWidget);
      },
    );

    testWidgets('tocar un aviso abre Mis reservas con esa reserva resaltada', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = FakeApi()
        ..notices = [
          reminderNotice.replaceFirst(
            '"booking_id": "00000000-0000-7000-8000-000000000001"',
            '"booking_id": "00000000-0000-7000-8000-000000000002"',
          ),
        ]
        ..unread = 1;
      await mountUser(
        tester,
        start: '/notificaciones',
        api: api.client,
        center: (sesion) => centerOf(api, sesion),
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

    testWidgets(
      'un aviso de cancelación abre el historial con esa reserva resaltada',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final api = FakeApi()
          ..notices = [
            noticeJson(
              id: '00000000-0000-7000-8000-000000000004',
              club: DateTime.utc(2026, 11, 12, 19, 58),
              kind: 'user_cancellation',
              title: 'Reserva cancelada',
              bookingId: '00000000-0000-7000-8000-000000000002',
            ),
          ]
          ..unread = 1;
        await mountUser(
          tester,
          start: '/notificaciones',
          api: api.client,
          center: (sesion) => centerOf(api, sesion),
        );

        await tester.tap(find.text('Reserva cancelada'));
        await tester.pumpAndSettle();

        expect(
          api.requests.any(
            (p) =>
                p.url.path == '/bookings' &&
                p.url.queryParameters['when'] == 'history',
          ),
          isTrue,
        );
        expect(
          tester
              .getSemantics(
                find.bySemanticsLabel(
                  RegExp('^Fútbol 5, Sede Morón, .*10:00 – 11:00'),
                ),
              )
              .flagsCollection
              .isSelected,
          isTrue,
        );
        semantica.dispose();
      },
    );

    testWidgets('sin reserva en el aviso abre Mis reservas sin resaltar nada', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = FakeApi();
      await mountUser(tester, start: '/reservas', api: api.client);

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
