import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_test.dart'
    show
        FakeApi,
        FakeSystem,
        noticesNow,
        alertNotice,
        centerOf,
        confirmationNotice,
        reminderNotice;
import 'support/mount.dart';
import 'support/user.dart';

void main() {
  setUpAll(loadFonts);

  Future<void> meetsGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  for (final dark in [true, false]) {
    final mode = dark ? 'dark' : 'light';
    final theme = dark ? darkTheme : lightTheme;

    Future<void> center(
      WidgetTester tester, {
      List<String> notices = const [],
      bool permission = true,
    }) async {
      final api = FakeApi()
        ..avisos = notices
        ..unread = notices.length;
      final session = FakeSession(userProfile);
      await mountScreen(
        tester,
        NotificationsScreen(
          center: centerOf(
            api,
            session,
            sistema: FakeSystem(concedido: permission),
          ),
          session: session,
          now: () => noticesNow,
          onOpen: (_, _) {},
        ),
        theme: theme,
      );
    }

    testWidgets('the center with notices meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await center(
        tester,
        notices: [reminderNotice, confirmationNotice, alertNotice],
      );
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets('the empty center meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await center(tester);
      await meetsGuidelines(tester);
      semantics.dispose();
    });

    testWidgets(
      '«Notificaciones desactivadas» meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await center(tester, permission: false);
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );

    testWidgets(
      'the panel with the app open meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final api = FakeApi();
        final notices = centerOf(api, FakeSession(userProfile));
        await mountScreen(
          tester,
          Stack(
            children: [
              const Scaffold(body: SizedBox.expand()),
              NoticePanel(
                center: notices,
                now: () => noticesNow,
                onOpen: (_) {},
              ),
            ],
          ),
          theme: theme,
        );
        api
          ..avisos = [reminderNotice]
          ..unread = 1;
        await tester.runAsync(notices.load);
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );

    testWidgets('the Home with the bell meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final api = FakeApi()
        ..avisos = [confirmationNotice, alertNotice]
        ..unread = 2;
      await mountUser(
        tester,
        dark: dark,
        start: '/inicio',
        api: api.cliente,
        center: (session) => centerOf(api, session),
      );
      await meetsGuidelines(tester);
      semantics.dispose();
    });
  }
}
