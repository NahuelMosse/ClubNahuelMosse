import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_test.dart'
    show FakeApi, noticesNow, centerOf, noticeJson, reminderNotice;
import 'support/mount.dart';
import 'support/user.dart';

final canceled = noticeJson(
  id: '00000000-0000-7000-8000-000000000005',
  club: DateTime.utc(2026, 11, 12, 19, 59),
  kind: 'user_cancellation',
  title: 'Reserva cancelada',
  body: 'Fútbol 5 · Sede Morón · Mié 11, 20:00. El horario quedó liberado.',
  bookingId: '00000000-0000-7000-8000-000000000002',
);

void main() {
  setUpAll(loadFonts);

  group('the cancellation confirmation in the panel', () {
    Future<(FakeApi, NotificationCenter)> open(
      WidgetTester tester, {
      required String location,
      Size size = const Size(393, 852),
      double scale = 1,
    }) async {
      final api = FakeApi();
      final session = FakeSession(userProfile);
      final center = centerOf(api, session)..location = () => location;
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(center: center, now: () => noticesNow, onOpen: (_) {}),
          ],
        ),
        theme: darkTheme,
        size: size,
        textScale: scale,
      );
      return (api, center);
    }

    Future<void> arrives(
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

    testWidgets('outside «Mis reservas» it opens the panel with the notice', (
      tester,
    ) async {
      final (api, center) = await open(tester, location: '/home');

      await arrives(tester, api, center, [canceled]);

      expect(find.text('Reserva cancelada'), findsOneWidget);
      expect(
        find.text(
          'Fútbol 5 · Sede Morón · Mié 11, 20:00. El horario quedó liberado.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'in «Mis reservas» it does not open the panel but counts as unread @assumption:CU-24.3-SUP-03',
      (tester) async {
        final (api, center) = await open(tester, location: '/bookings');

        await arrives(tester, api, center, [canceled]);

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(find.text('Reserva cancelada'), findsNothing);
        expect(center.unread, 1);
        expect(center.list.single.read, isFalse);
      },
    );

    testWidgets(
      'what was silenced does not return to the panel when another notice arrives @assumption:CU-24.3-SUP-07',
      (tester) async {
        final (api, center) = await open(tester, location: '/bookings');
        await arrives(tester, api, center, [canceled]);

        await arrives(tester, api, center, [
          reminderNotice.replaceFirst(
            '"id": "00000000-0000-7000-8000-000000000003"',
            '"id": "00000000-0000-7000-8000-000000000006"',
          ),
          canceled,
        ]);

        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        expect(find.text('Reserva cancelada'), findsNothing);
        expect(center.unread, 2);
      },
    );

    for (final width in [360.0, 430.0]) {
      testWidgets(
        'with text at 200 % at ${width.toInt()} wide it fits on the screen',
        (tester) async {
          final (api, center) = await open(
            tester,
            location: '/home',
            size: Size(width, 800),
            scale: 2,
          );

          await arrives(tester, api, center, [canceled]);

          expect(tester.takeException(), isNull);
          expect(find.text('Reserva cancelada'), findsOneWidget);
          expect(
            tester.getBottomRight(find.text('MARCAR TODAS')).dx,
            lessThanOrEqualTo(width),
          );
        },
      );
    }
  });

  group('when tapping the confirmation', () {
    testWidgets(
      'it opens «Mis reservas» on the history @assumption:CU-24.3-SUP-06',
      (tester) async {
        final api = FakeApi()
          ..notices = [canceled]
          ..unread = 1;
        await mountUser(
          tester,
          start: '/notifications',
          api: api.client,
          center: (session) => centerOf(api, session),
        );
        api.requests.clear();

        await tester.tap(find.text('Reserva cancelada'));
        await tester.pumpAndSettle();

        expect(find.text('Mis reservas'), findsOneWidget);
        expect(
          api.of('GET', '/bookings').map((p) => p.url.queryParameters['when']),
          ['history'],
        );
      },
    );

    testWidgets('a reminder still opens the upcoming ones', (tester) async {
      final api = FakeApi()
        ..notices = [reminderNotice]
        ..unread = 1;
      await mountUser(
        tester,
        start: '/notifications',
        api: api.client,
        center: (session) => centerOf(api, session),
      );
      api.requests.clear();

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(
        api.of('GET', '/bookings').map((p) => p.url.queryParameters['when']),
        ['upcoming'],
      );
    });
  });
}
