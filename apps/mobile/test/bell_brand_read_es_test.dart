import 'dart:async';

import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_spanish_test.dart'
    show FakeApi, FakeSystem, centerOf, noticeJson, reminderNotice, noticesNow;
import 'support/mount.dart';
import 'support/user.dart';

const _booking1 = '00000000-0000-7000-8000-000000000001';
const _booking2 = '00000000-0000-7000-8000-000000000002';
const _reminderId = '00000000-0000-7000-8000-000000000003';

/// A system where the test decides when the person taps a notice in the tray.
class SystemWithTaps extends FakeSystem {
  final taps = StreamController<NoticeTapped>.broadcast();

  @override
  Stream<NoticeTapped> get onTap => taps.stream;
}

Future<(FakeApi, NotificationCenter)> _openCenter(
  WidgetTester tester, {
  required List<String> notices,
}) async {
  final api = FakeApi()
    ..notices = notices
    ..unread = notices.length;
  final session = FakeSession(userProfile);
  final center = centerOf(api, session);
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
  return (api, center);
}

/// The whole app with unread [notices] and a system where the test taps the notices.
Future<(FakeApi, SystemWithTaps, NotificationCenter)> _mountApp(
  WidgetTester tester,
  List<String> notices,
) async {
  final api = FakeApi()
    ..notices = notices
    ..unread = notices.length;
  final system = SystemWithTaps();
  addTearDown(system.taps.close);
  late NotificationCenter center;
  await mountUser(
    tester,
    start: '/inicio',
    api: api.client,
    center: (session) => center = centerOf(api, session, system: system),
  );
  return (api, system, center);
}

Future<void> _leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadFonts);

  group('leaving the notification center', () {
    testWidgets(
      'opening the bell and going back marks the shown ones as read and the bell at zero @NOT-03-S1',
      (tester) async {
        final (api, center) = await _openCenter(
          tester,
          notices: [reminderNotice],
        );
        expect(center.unread, 1);

        await _leave(tester);

        expect(api.of('POST', '/notifications/read-all'), hasLength(1));
        expect(center.unread, 0);
        expect(center.list.every((n) => n.read), isTrue);
      },
    );

    testWidgets(
      'with the center open the new ones stay marked unread @NOT-03-S1',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final (api, center) = await _openCenter(
          tester,
          notices: [reminderNotice],
        );

        expect(find.bySemanticsLabel(RegExp('sin leer')), findsOneWidget);
        expect(center.unread, 1);
        expect(api.of('POST', '/notifications/read-all'), isEmpty);
        semantics.dispose();
      },
    );

    testWidgets(
      'if the API does not answer on leaving they show as read and the next read corrects it @assumption:NOT-03-ASM-02',
      (tester) async {
        final (api, center) = await _openCenter(
          tester,
          notices: [reminderNotice],
        );
        api.down = true;

        await _leave(tester);

        expect(center.unread, 0);
        expect(center.list.every((n) => n.read), isTrue);

        api.down = false;
        await tester.runAsync(center.load);
        expect(center.unread, 1);
      },
    );
  });

  group('tapping a push', () {
    testWidgets(
      'tapping a push marks as read those of that kind and booking and opens the booking @NOT-03-S2',
      (tester) async {
        final otherBooking = noticeJson(
          id: '00000000-0000-7000-8000-000000000005',
          club: DateTime.utc(2026, 11, 12, 19, 50),
          bookingId: _booking2,
        );
        final otherKind = noticeJson(
          id: '00000000-0000-7000-8000-000000000006',
          club: DateTime.utc(2026, 11, 12, 19, 40),
          kind: 'user_cancellation',
          title: 'Reserva cancelada',
        );
        final (api, system, center) = await _mountApp(tester, [
          reminderNotice,
          otherBooking,
          otherKind,
        ]);

        system.taps.add(
          NoticeTapped(kind: NotificationKind.reminder, bookingId: _booking1),
        );
        await tester.pumpAndSettle();

        final read = api.requests
            .where((p) => p.method == 'POST' && p.url.path.endsWith('/read'))
            .map((p) => p.url.path)
            .toList();
        expect(read, ['/notifications/$_reminderId/read']);
        expect(center.unreadList, hasLength(2));
        expect(find.text('Mis reservas'), findsOneWidget);
      },
    );

    testWidgets(
      'a push that is not tapped stays unread @assumption:NOT-03-ASM-01',
      (tester) async {
        final (api, _, center) = await _mountApp(tester, [reminderNotice]);

        expect(center.unread, 1);
        expect(api.of('POST', '/notifications/$_reminderId/read'), isEmpty);
        expect(api.of('POST', '/notifications/read-all'), isEmpty);
      },
    );
  });
}
