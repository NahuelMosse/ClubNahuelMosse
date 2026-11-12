import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Tristate;

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

/// 20:00 on Thursday, November 12, in club time.
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
  body: 'Vóley · Sede Ramos Mejía · Mié 11, 20:00. El horario quedó liberado.',
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

Map<String, Object?> bodyOf(http.Request request) =>
    jsonDecode(request.body) as Map<String, Object?>;

class FakeSystem implements NotificationSystem {
  FakeSystem({this.granted = true});

  bool granted;
  int requests = 0;
  int forgets = 0;

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
  Future<void> forgetToken() async => forgets++;

  @override
  Stream<void> get onArrive => const Stream.empty();

  @override
  Stream<NoticeTapped> get onTap => const Stream.empty();

  @override
  Future<NoticeTapped?> openedBy() async => null;
}

/// A system whose permission answers whenever the test decides.
class SlowSystem extends FakeSystem {
  final response = Completer<bool>();

  @override
  Future<bool> isAllowed() => response.future;
}

/// Firebase with a slow sign-out, like on a real phone.
class SlowCredentials extends FakeCredentials {
  SlowCredentials({this.delay = const Duration(milliseconds: 100)});

  final Duration delay;

  /// While `true`, the token never arrives.
  bool noToken = false;

  @override
  Future<String?> token() =>
      noToken ? Completer<String?>().future : super.token();

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(delay);
    await super.signOut();
  }
}

/// The notifications API, returning what the center holds and recording each request.
class FakeApi {
  List<String> notices = [];
  int unread = 0;
  bool down = false;
  final requests = <http.Request>[];
  void Function(http.Request)? onRequest;

  ApiClient get client => ApiClient(
    'http://api.falsa',
    client: MockClient((request) async {
      requests.add(request);
      onRequest?.call(request);
      if (down) throw http.ClientException('sin red');
      final (code, responseBody) = switch ((request.method, request.url.path)) {
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
        ('POST', final path) when path.endsWith('/read') => (204, ''),
        _ => (404, '{}'),
      };
      return http.Response.bytes(
        utf8.encode(responseBody),
        code,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  );

  Iterable<http.Request> of(String method, String path) =>
      requests.where((p) => p.method == method && p.url.path == path);
}

/// By default the phone is at 21:00 club time on November 12: what was already unread at 19:58
/// did not arrive while the app was starting.
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

  group('when it arrived and on which day', () {
    final today = DateTime.utc(2026, 11, 12, 20);

    test('the day label is «HOY», «AYER» or the date', () {
      expect(dayLabel(DateTime.utc(2026, 11, 12, 0, 5), today), 'HOY');
      expect(dayLabel(DateTime.utc(2026, 11, 11, 23, 59), today), 'AYER');
      expect(dayLabel(DateTime.utc(2026, 11, 9, 9), today), '09/11');
    });

    test('when it arrived is counted from now back to yesterday', () {
      expect(
        arrivedLabel(DateTime.utc(2026, 11, 12, 19, 59, 30), today),
        'AHORA',
      );
      expect(
        arrivedLabel(DateTime.utc(2026, 11, 12, 19, 58), today),
        'HACE 2 MIN',
      );
      expect(arrivedLabel(DateTime.utc(2026, 11, 12, 17), today), 'HACE 3 H');
      expect(arrivedLabel(DateTime.utc(2026, 11, 11, 15), today), 'AYER');
      expect(arrivedLabel(DateTime.utc(2026, 11, 3, 15), today), '03/11');
    });

    test('groups by day keeping newest to oldest', () {
      final list = [
        for (final json in [reminderNotice, confirmationNotice, alertNotice])
          AppNotification.fromJson(jsonDecode(json))!,
      ];

      final groups = groupByDay(list, today);

      expect(groups.map((g) => g.label), ['HOY', 'AYER']);
      expect(groups.first.notifications.map((n) => n.id), [
        '00000000-0000-7000-8000-000000000003',
        '00000000-0000-7000-8000-000000000002',
      ]);
    });

    test('each notice leads to the matching «Mis reservas» tab', () {
      expect(
        noticeRoute(
          NotificationKind.reminder,
          '00000000-0000-7000-8000-000000000007',
        ),
        '/bookings?booking=00000000-0000-7000-8000-000000000007',
      );
      expect(
        noticeRoute(
          NotificationKind.forcedCancellation,
          '00000000-0000-7000-8000-000000000007',
        ),
        '/bookings?history=1&booking=00000000-0000-7000-8000-000000000007',
      );
      expect(
        noticeRoute(
          NotificationKind.userCancellation,
          '00000000-0000-7000-8000-000000000007',
        ),
        '/bookings?history=1&booking=00000000-0000-7000-8000-000000000007',
      );
      expect(noticeRoute(NotificationKind.reminder, null), '/bookings');
      expect(noticeRoute(null, null), '/bookings');
    });

    test('a kind the app does not know is not read', () {
      expect(
        AppNotification.fromJson(
          jsonDecode(
            noticeJson(
              id: '00000000-0000-7000-8000-000000000009',
              club: today,
              kind: 'otra',
            ),
          ),
        ),
        isNull,
      );
    });
  });

  group('the center', () {
    Future<(FakeApi, NotificationCenter)> open(
      WidgetTester tester, {
      List<String> notices = const [],
      int unread = 0,
      bool permission = true,
      Size size = const Size(393, 852),
      double scale = 1,
      bool dark = true,
      void Function(AppNotification)? onOpened,
    }) async {
      final api = FakeApi()
        ..notices = [...notices]
        ..unread = unread;
      final session = FakeSession(userProfile);
      final center = centerOf(
        api,
        session,
        system: FakeSystem(granted: permission),
      );
      await mountScreen(
        tester,
        NotificationsScreen(
          center: center,
          session: session,
          now: () => noticesNow,
          onOpen: (_, n) => onOpened?.call(n),
        ),
        theme: dark ? darkTheme : lightTheme,
        size: size,
        textScale: scale,
      );
      return (api, center);
    }

    testWidgets('groups by day, marks the unread and keeps the order', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(
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
      semantics.dispose();
    });

    testWidgets(
      'with no notices and with permission it says there are none yet',
      (tester) async {
        await open(tester);

        expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
        expect(
          find.text('Acá vas a ver los recordatorios de tus reservas.'),
          findsOneWidget,
        );
        expect(find.text('ACTIVAR NOTIFICACIONES'), findsNothing);
      },
    );

    testWidgets(
      'without permission it offers to enable them and on enabling registers the phone with permission',
      (tester) async {
        final (api, _) = await open(tester, permission: false);
        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(
          find.text(
            'Activá los avisos para que te recordemos tus reservas una hora antes.',
          ),
          findsOneWidget,
        );
        final before = bodyOf(api.of('PUT', '/devices').last);
        expect(before['permission_granted'], isFalse);

        await tester.tap(find.text('ACTIVAR NOTIFICACIONES'));
        await tester.pumpAndSettle();

        expect(find.text('Notificaciones desactivadas'), findsNothing);
        expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
        final after = bodyOf(api.of('PUT', '/devices').last);
        expect(after, {
          'token': 'token-del-telefono',
          'platform': 'android',
          'permission_granted': true,
        });
      },
    );

    testWidgets(
      'without permission but with notices, it shows them below the banner',
      (tester) async {
        await open(
          tester,
          notices: [reminderNotice],
          unread: 1,
          permission: false,
        );

        expect(find.text('Notificaciones desactivadas'), findsOneWidget);
        expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      },
    );

    testWidgets('tapping a notice marks it read and opens it', (tester) async {
      AppNotification? opened;
      final (api, _) = await open(
        tester,
        notices: [reminderNotice],
        unread: 1,
        onOpened: (n) => opened = n,
      );

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(opened?.bookingId, '00000000-0000-7000-8000-000000000001');
      expect(
        api.of(
          'POST',
          '/notifications/00000000-0000-7000-8000-000000000003/read',
        ),
        hasLength(1),
      );
    });

    testWidgets(
      'with no connection it reports the error and on retry shows the list',
      (tester) async {
        final api = FakeApi()
          ..notices = [reminderNotice]
          ..unread = 1
          ..down = true;
        final session = FakeSession(userProfile);
        await mountScreen(
          tester,
          NotificationsScreen(
            center: centerOf(api, session),
            session: session,
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
      'if the read fails it does not show an empty center left from before',
      (tester) async {
        final api = FakeApi();
        final session = FakeSession(userProfile);
        final center = centerOf(api, session);
        await tester.runAsync(center.load);
        api.down = true;
        await mountScreen(
          tester,
          NotificationsScreen(
            center: center,
            session: session,
            now: () => noticesNow,
            onOpen: (_, _) {},
          ),
          theme: darkTheme,
        );

        expect(find.text('Error de conexión'), findsOneWidget);
        expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      },
    );

    for (final (name, dark) in [('dark', true), ('light', false)]) {
      testWidgets(
        'with text at 200 % on a 360 width nothing is clipped ($name)',
        (tester) async {
          await open(
            tester,
            notices: [reminderNotice, confirmationNotice, alertNotice],
            unread: 1,
            size: const Size(360, 800),
            scale: 2,
            dark: dark,
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
        'the disabled ones with text at 200 % on a 360 width ($name)',
        (tester) async {
          await open(
            tester,
            permission: false,
            size: const Size(360, 800),
            scale: 2,
            dark: dark,
          );

          expect(tester.takeException(), isNull);
          expect(find.text('Notificaciones desactivadas'), findsOneWidget);
          expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
        },
      );
    }
  });

  group('the panel with the app open', () {
    Future<(FakeApi, NotificationCenter, List<AppNotification>)> open(
      WidgetTester tester, {
      bool permission = true,
      Size size = const Size(393, 852),
      double scale = 1,
    }) async {
      final api = FakeApi();
      final session = FakeSession(userProfile);
      final center = centerOf(
        api,
        session,
        system: FakeSystem(granted: permission),
      );
      final opened = <AppNotification>[];
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(
              center: center,
              now: () => noticesNow,
              onOpen: opened.add,
            ),
          ],
        ),
        theme: darkTheme,
        size: size,
        textScale: scale,
      );
      return (api, center, opened);
    }

    Future<void> arrive(
      WidgetTester tester,
      FakeApi api,
      NotificationCenter center,
      List<String> notices,
    ) async {
      api
        ..notices = notices
        ..unread = notices.length;
      await tester.runAsync(center.load);
      await tester.pumpAndSettle();
    }

    testWidgets(
      'what was already unread when the app opened does not open the panel',
      (tester) async {
        final api = FakeApi()
          ..notices = [reminderNotice]
          ..unread = 1;
        final session = FakeSession(userProfile);
        final center = centerOf(api, session);
        await mountScreen(
          tester,
          NoticePanel(center: center, onOpen: (_) {}),
          theme: darkTheme,
        );

        expect(center.unread, 1);
        expect(find.text('MARCAR TODAS'), findsNothing);
      },
    );

    testWidgets(
      'an arriving notice opens the panel without leaving the screen',
      (tester) async {
        final (api, center, _) = await open(tester);

        await arrive(tester, api, center, [reminderNotice]);

        expect(find.text('NOTIFICACIONES'), findsOneWidget);
        expect(find.text('MARCAR TODAS'), findsOneWidget);
        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        expect(find.text('la pantalla de abajo'), findsOneWidget);
      },
    );

    testWidgets('«Marcar todas» reads them and closes the panel', (
      tester,
    ) async {
      final (api, center, _) = await open(tester);
      await arrive(tester, api, center, [reminderNotice]);

      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(center.unread, 0);
      expect(api.of('POST', '/notifications/read-all'), hasLength(1));
    });

    testWidgets('tapping outside closes the panel without marking anything', (
      tester,
    ) async {
      final (api, center, _) = await open(tester);
      await arrive(tester, api, center, [reminderNotice]);

      await tester.tap(
        find.bySemanticsLabel('Cerrar las notificaciones'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(center.unread, 1);
      expect(api.of('POST', '/notifications/read-all'), isEmpty);
    });

    testWidgets('tapping a notice opens it', (tester) async {
      final (api, center, opened) = await open(tester);
      await arrive(tester, api, center, [reminderNotice]);

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(opened.map((n) => n.id), ['00000000-0000-7000-8000-000000000003']);
    });

    testWidgets('without system permission it does not open the panel', (
      tester,
    ) async {
      final (api, center, _) = await open(tester, permission: false);

      await arrive(tester, api, center, [reminderNotice]);

      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(center.unread, 1);
    });

    testWidgets(
      'system back closes the panel without marking anything or touching what is below',
      (tester) async {
        final (api, center, _) = await open(tester);
        await arrive(tester, api, center, [reminderNotice]);
        expect(find.text('MARCAR TODAS'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(center.unread, 1);
        expect(find.text('la pantalla de abajo'), findsOneWidget);
      },
    );

    testWidgets(
      'with the panel open the screen reader does not reach what is below and announces it',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final (api, center, _) = await open(tester);
        List<String> labels() => [
          for (final node in tester.semantics.simulatedAccessibilityTraversal())
            node.label,
        ];
        expect(labels(), contains('la pantalla de abajo'));

        await arrive(tester, api, center, [reminderNotice]);

        expect(labels(), isNot(contains('la pantalla de abajo')));
        expect(labels(), contains('MARCAR TODAS'));
        expect(
          tester
              .getSemantics(find.text('NOTIFICACIONES'))
              .flagsCollection
              .isLiveRegion,
          isTrue,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(labels(), contains('la pantalla de abajo'));
        semantics.dispose();
      },
    );

    for (final width in [360.0, 430.0]) {
      testWidgets(
        'with text at 200 % on a ${width.toInt()} width it fits on screen',
        (tester) async {
          final (api, center, _) = await open(
            tester,
            size: Size(width, 800),
            scale: 2,
          );

          await arrive(tester, api, center, [
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
            lessThanOrEqualTo(width),
          );
        },
      );
    }
  });

  group('when the panel opens', () {
    Future<(FakeApi, NotificationCenter)> mountPanel(
      WidgetTester tester,
      List<String> notices,
    ) async {
      final api = FakeApi()
        ..notices = notices
        ..unread = notices.length;
      final center = centerOf(api, FakeSession(userProfile), now: DateTime.now);
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: SizedBox.expand()),
            NoticePanel(center: center, onOpen: (_) {}),
          ],
        ),
        theme: darkTheme,
      );
      return (api, center);
    }

    Future<void> arrive(
      WidgetTester tester,
      FakeApi api,
      NotificationCenter center,
      List<String> notices,
    ) async {
      api
        ..notices = notices
        ..unread = notices.length;
      await tester.runAsync(center.load);
      await tester.pumpAndSettle();
    }

    String recent(String id) =>
        noticeJson(id: id, club: inClubTime(DateTime.now()));

    testWidgets('what arrives while the app starts opens the panel', (
      tester,
    ) async {
      await mountPanel(tester, [
        recent('00000000-0000-7000-8000-000000000005'),
      ]);

      expect(find.text('MARCAR TODAS'), findsOneWidget);
    });

    testWidgets(
      'if the panel was closed unread, what arrives later does not reopen it',
      (tester) async {
        final (api, center) = await mountPanel(tester, []);
        await arrive(tester, api, center, [
          recent('00000000-0000-7000-8000-000000000005'),
        ]);
        expect(find.text('MARCAR TODAS'), findsOneWidget);

        await tester.tap(
          find.bySemanticsLabel('Cerrar las notificaciones'),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await arrive(tester, api, center, [
          recent('00000000-0000-7000-8000-000000000006'),
          recent('00000000-0000-7000-8000-000000000005'),
        ]);

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(center.unread, 2);
      },
    );

    testWidgets(
      'after reading everything, what arrives opens the panel again',
      (tester) async {
        final (api, center) = await mountPanel(tester, []);
        await arrive(tester, api, center, [
          recent('00000000-0000-7000-8000-000000000005'),
        ]);
        await tester.tap(find.text('MARCAR TODAS'));
        await tester.pumpAndSettle();

        await arrive(tester, api, center, [
          recent('00000000-0000-7000-8000-000000000006'),
        ]);

        expect(find.text('MARCAR TODAS'), findsOneWidget);
      },
    );
  });

  group('signing out', () {
    testWidgets('closing deletes the phone token', (tester) async {
      final api = FakeApi();
      final system = FakeSystem();
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: api.client,
        ),
      );
      centerOf(api, session, system: system);
      await tester.runAsync(() async {
        await session.signIn('nahuel@correo.com', 'ClubNahuel1');
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await session.close();
      });

      expect(system.forgets, 1);
    });

    testWidgets('a session that is no longer valid also deletes the token', (
      tester,
    ) async {
      final api = FakeApi();
      final system = FakeSystem();
      final credentials = FakeCredentials(withAccount: true)..tokenFails = true;
      final session = Session(
        repository: SessionRepository(
          credentials: credentials,
          api: api.client,
        ),
      );
      centerOf(api, session, system: system);

      final profile = await tester.runAsync(session.resume);

      expect(profile, isNull);
      expect(credentials.signOuts, 1);
      expect(system.forgets, 1);
    });

    testWidgets('if the profile fails after signing in, also', (tester) async {
      final api = FakeApi();
      final system = FakeSystem();
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: ApiClient(
            'http://api.falsa',
            client: MockClient((_) async => http.Response('{}', 500)),
          ),
        ),
      );
      centerOf(api, session, system: system);

      await tester.runAsync(() async {
        await expectLater(
          session.signIn('nahuel@correo.com', 'ClubNahuel1'),
          throwsA(isA<ServerError>()),
        );
      });

      expect(system.forgets, 1);
    });

    testWidgets('deactivating the account deletes the token', (tester) async {
      final api = FakeApi();
      final system = FakeSystem();
      final session = Session(
        repository: SessionRepository(
          credentials: FakeCredentials(),
          api: api.client,
        ),
      );
      centerOf(api, session, system: system);
      await tester.runAsync(() async {
        await session.signIn('nahuel@correo.com', 'ClubNahuel1');
        await session.deactivate();
      });

      expect(system.forgets, 1);
    });

    testWidgets('with nothing to notify, closing does not wait for the token', (
      tester,
    ) async {
      final credentials = SlowCredentials(delay: Duration.zero);
      final session = Session(
        repository: SessionRepository(
          credentials: credentials,
          api: FakeApi().client,
        ),
      );
      await tester.runAsync(
        () => session.signIn('nahuel@correo.com', 'ClubNahuel1'),
      );
      credentials.noToken = true;

      await tester.runAsync(session.close);

      expect(credentials.signOuts, 1);
    });

    testWidgets(
      'with the token hanging, closing waits two seconds and signs out anyway',
      (tester) async {
        final credentials = SlowCredentials(delay: Duration.zero);
        final session = Session(
          repository: SessionRepository(
            credentials: credentials,
            api: FakeApi().client,
          ),
        );
        session.onClose.add((_) async => fail('there was no token to give'));
        await tester.runAsync(
          () => session.signIn('nahuel@correo.com', 'ClubNahuel1'),
        );
        credentials.noToken = true;
        var closed = false;

        unawaited(session.close().then((_) => closed = true));
        await tester.pump(const Duration(seconds: 1));
        expect(closed, isFalse);
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(closed, isTrue);
        expect(credentials.signOuts, 1);
      },
    );

    testWidgets(
      'if the unregister fails before sign-out finishes, no uncaught error is left',
      (tester) async {
        final credentials = SlowCredentials();
        final session = Session(
          repository: SessionRepository(
            credentials: credentials,
            api: FakeApi().client,
          ),
        );
        session.onClose.add(
          (_) => Future<void>.error(StateError('the API went down')),
        );
        await tester.runAsync(
          () => session.signIn('nahuel@correo.com', 'ClubNahuel1'),
        );

        await tester.runAsync(session.close);

        expect(tester.takeException(), isNull);
        expect(credentials.signOuts, 1);
        expect(session.profile, isNull);
      },
    );
  });

  group('periodic polling', () {
    int reads(FakeApi api) => api.of('GET', '/notifications').length;

    testWidgets('a center disposed while starting leaves no live timer', (
      tester,
    ) async {
      final api = FakeApi();
      final system = SlowSystem();
      final center = NotificationCenter(
        notifications: NotificationsRepository(
          api: api.client,
          session: FakeSession(userProfile),
        ),
        session: FakeSession(userProfile),
        system: system,
        every: const Duration(seconds: 5),
      );

      center.dispose();
      system.response.complete(true);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(seconds: 30));

      expect(reads(api), 0);
    });

    testWidgets(
      'in the background it does not poll and on return reads right away',
      (tester) async {
        final api = FakeApi();
        final center = NotificationCenter(
          notifications: NotificationsRepository(
            api: api.client,
            session: FakeSession(userProfile),
          ),
          session: FakeSession(userProfile),
          system: FakeSystem(),
          every: const Duration(seconds: 10),
        );
        await tester.pump(const Duration(seconds: 1));
        final atStart = reads(api);
        await tester.pump(const Duration(seconds: 25));
        final withAppOpen = reads(api);
        expect(withAppOpen, greaterThan(atStart));

        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        await tester.pump(const Duration(seconds: 60));
        expect(reads(api), withAppOpen);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(reads(api), withAppOpen + 1);

        center.dispose();
        await tester.pump();
      },
    );
  });

  group('the phone and the session', () {
    testWidgets('registers the phone with the permission it has', (
      tester,
    ) async {
      final api = FakeApi();
      centerOf(
        api,
        FakeSession(userProfile),
        system: FakeSystem(granted: false),
      );
      await tester.pumpAndSettle();

      final request = bodyOf(api.of('PUT', '/devices').single);
      expect(request['permission_granted'], isFalse);
      expect(request['token'], 'token-del-telefono');
    });

    testWidgets(
      'if disposed with a request in flight, on finishing it notifies no one',
      (tester) async {
        final api = FakeApi();
        final center = centerOf(api, FakeSession(userProfile));

        center.dispose();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('an admin does not register a phone or query the center', (
      tester,
    ) async {
      final api = FakeApi();
      centerOf(api, FakeSession(adminProfile));
      await tester.pumpAndSettle();

      expect(api.requests, isEmpty);
    });

    testWidgets(
      'on signing out it unregisters the phone with the session being closed',
      (tester) async {
        final api = FakeApi();
        final credentials = FakeCredentials();
        final session = Session(
          repository: SessionRepository(
            credentials: credentials,
            api: api.client,
          ),
        );
        String? unregisterAuthorization;
        api.onRequest = (p) {
          if (p.url.path == '/devices/unregister') {
            unregisterAuthorization = p.headers['authorization'];
          }
        };
        final center = centerOf(api, session);
        await tester.runAsync(() async {
          await session.signIn('nahuel@correo.com', 'ClubNahuel1');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        expect(api.of('PUT', '/devices'), hasLength(1));

        await tester.runAsync(session.close);
        await tester.pumpAndSettle();

        expect(api.of('POST', '/devices/unregister'), hasLength(1));
        expect(bodyOf(api.of('POST', '/devices/unregister').single), {
          'token': 'token-del-telefono',
        });
        // The unregister goes with the session that was closed, taken before closing it.
        expect(unregisterAuthorization, 'Bearer token-falso');
        expect(credentials.signOuts, 1);
        expect(center.list, isEmpty);
      },
    );

    testWidgets(
      'if the phone cannot be unregistered, the session closes anyway',
      (tester) async {
        final api = FakeApi();
        final credentials = FakeCredentials();
        final session = Session(
          repository: SessionRepository(
            credentials: credentials,
            api: api.client,
          ),
        );
        centerOf(api, session);
        await tester.runAsync(() async {
          await session.signIn('nahuel@correo.com', 'ClubNahuel1');
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();

        api.down = true;
        await tester.runAsync(session.close);

        expect(credentials.signOuts, 1);
        expect(session.profile, isNull);
      },
    );
  });

  group('the bell and «Mis reservas»', () {
    testWidgets(
      'the Home bell counts the unread and opens the center @assumption:CU-24.1-SUP-10',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final api = FakeApi()
          ..notices = [reminderNotice, confirmationNotice]
          ..unread = 2;
        await mountUser(
          tester,
          start: '/home',
          api: api.client,
          center: (session) => centerOf(api, session),
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
        semantics.dispose();
      },
    );

    testWidgets('with no unread notices the bell counts nothing', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final api = FakeApi();
      await mountUser(
        tester,
        start: '/home',
        api: api.client,
        center: (session) => centerOf(api, session),
      );

      expect(find.bySemanticsLabel('Notificaciones'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('with no center the Home has no bell', (tester) async {
      final semantics = tester.ensureSemantics();
      await mountUser(tester, start: '/home', api: FakeApi().client);

      expect(find.bySemanticsLabel(RegExp('^Notificaciones')), findsNothing);
      semantics.dispose();
    });

    testWidgets(
      'an admin does not reach the center @assumption:CU-24.1-SUP-10',
      (tester) async {
        await mountAdmin(
          tester,
          start: '/notifications',
          api: FakeApi().client,
        );

        expect(find.text('Notificaciones'), findsNothing);
        expect(find.text('PANEL ADMIN'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a notice opens «Mis reservas» with that booking highlighted',
      (tester) async {
        final semantics = tester.ensureSemantics();
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
          start: '/notifications',
          api: api.client,
          center: (session) => centerOf(api, session),
        );

        await tester.tap(find.text('Tu reserva es en 1 hora'));
        await tester.pumpAndSettle();

        expect(find.text('Mis reservas'), findsOneWidget);
        bool highlighted(String timeSlot) => tester
            .getSemantics(
              find.bySemanticsLabel(
                RegExp('^Fútbol 5, Sede Morón, .*$timeSlot'),
              ),
            )
            .flagsCollection
            .isSelected == Tristate.isTrue;
        expect(highlighted('10:00 – 11:00'), isTrue);
        expect(highlighted('21:00 – 22:00'), isFalse);
        semantics.dispose();
      },
    );

    testWidgets(
      'a cancellation notice opens the history with that booking highlighted',
      (tester) async {
        final semantics = tester.ensureSemantics();
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
          start: '/notifications',
          api: api.client,
          center: (session) => centerOf(api, session),
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
              .isSelected == Tristate.isTrue,
          isTrue,
        );
        semantics.dispose();
      },
    );

    testWidgets(
      'with no booking in the notice it opens «Mis reservas» highlighting nothing',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final api = FakeApi();
        await mountUser(tester, start: '/bookings', api: api.client);

        expect(
          tester
              .getSemantics(
                find.bySemanticsLabel(
                  RegExp('^Fútbol 5, Sede Morón, .*21:00 – 22:00'),
                ),
              )
              .flagsCollection
              .isSelected == Tristate.isTrue,
          isFalse,
        );
        semantics.dispose();
      },
    );
  });
}
