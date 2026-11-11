import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../notifications_spanish_test.dart'
    show
        FakeApi,
        FakeSystem,
        noticesNow,
        alertNotice,
        centerOf,
        confirmationNotice,
        reminderNotice;
import '../support/mount.dart';
import '../support/fixed_clock.dart';
import '../support/user.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  const modes = {'dark': true, 'light': false};

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: dark) in modes.entries) {
      Future<void> center(
        WidgetTester tester, {
        List<String> notices = const [],
        int unread = 0,
        bool permission = true,
        double scale = 1,
      }) async {
        final api = FakeApi()
          ..notices = notices
          ..unread = unread;
        final session = FakeSession(userProfile);
        await mountScreen(
          tester,
          NotificationsScreen(
            center: centerOf(
              api,
              session,
              system: FakeSystem(granted: permission),
            ),
            session: session,
            now: () => noticesNow,
            onOpen: (_, _) {},
          ),
          theme: dark ? darkTheme : lightTheme,
          size: size,
          textScale: scale,
        );
      }

      testWidgets('center $width $mode', (tester) async {
        await center(
          tester,
          notices: [reminderNotice, confirmationNotice, alertNotice],
          unread: 1,
        );
        await capture(tester, 'notifications/center_${width}_$mode.png');
      });

      testWidgets('center with text at 200 % $width $mode', (tester) async {
        await center(
          tester,
          notices: [reminderNotice, confirmationNotice, alertNotice],
          unread: 1,
          scale: 2,
        );
        await capture(tester, 'notifications/center_200_${width}_$mode.png');
      });

      testWidgets('empty center $width $mode', (tester) async {
        await center(tester);
        await capture(tester, 'notifications/empty_${width}_$mode.png');
      });

      testWidgets('notifications disabled $width $mode', (tester) async {
        await center(tester, permission: false);
        await capture(tester, 'notifications/disabled_${width}_$mode.png');
      });

      testWidgets('disabled with notices $width $mode', (tester) async {
        await center(
          tester,
          notices: [reminderNotice],
          unread: 1,
          permission: false,
        );
        await capture(
          tester,
          'notifications/disabled_with_notices_${width}_$mode.png',
        );
      });

      testWidgets('home with the bell $width $mode', (tester) async {
        final api = FakeApi()
          ..notices = [reminderNotice, confirmationNotice]
          ..unread = 2;
        await mountUser(
          tester,
          dark: dark,
          size: size,
          start: '/home',
          api: api.client,
          center: (session) => centerOf(api, session),
        );
        await capture(tester, 'notifications/home_${width}_$mode.png');
      });

      testWidgets('panel with the app open $width $mode', (tester) async {
        final api = FakeApi();
        final noticeCenter = centerOf(api, FakeSession(userProfile));
        await mountScreen(
          tester,
          Stack(
            children: [
              const Scaffold(body: SizedBox.expand()),
              NoticePanel(
                center: noticeCenter,
                now: () => noticesNow,
                onOpen: (_) {},
              ),
            ],
          ),
          theme: dark ? darkTheme : lightTheme,
          size: size,
        );
        api
          ..notices = [
            reminderNotice,
            confirmationNotice.replaceFirst('"read": true', '"read": false'),
            alertNotice.replaceFirst('"read": true', '"read": false'),
          ]
          ..unread = 3;
        await tester.runAsync(noticeCenter.load);
        await capture(tester, 'notifications/panel_${width}_$mode.png');
      });
    }
  }
}
