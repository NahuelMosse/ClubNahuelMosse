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

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  for (final oscuro in [true, false]) {
    final modo = oscuro ? 'oscuro' : 'claro';
    final tema = oscuro ? darkTheme : lightTheme;

    Future<void> centro(
      WidgetTester tester, {
      List<String> avisos = const [],
      bool permiso = true,
    }) async {
      final api = FakeApi()
        ..avisos = avisos
        ..unread = avisos.length;
      final sesion = FakeSession(userProfile);
      await mountScreen(
        tester,
        NotificationsScreen(
          center: centerOf(
            api,
            sesion,
            sistema: FakeSystem(concedido: permiso),
          ),
          session: sesion,
          now: () => noticesNow,
          onOpen: (_, _) {},
        ),
        theme: tema,
      );
    }

    testWidgets('el centro con avisos cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await centro(
        tester,
        avisos: [reminderNotice, confirmationNotice, alertNotice],
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el centro vacío cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await centro(tester);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets(
      '«Notificaciones desactivadas» cumple las guías en modo $modo',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await centro(tester, permiso: false);
        await cumpleLasGuias(tester);
        semantica.dispose();
      },
    );

    testWidgets('el panel con la app abierta cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = FakeApi();
      final avisos = centerOf(api, FakeSession(userProfile));
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: SizedBox.expand()),
            NoticePanel(center: avisos, now: () => noticesNow, onOpen: (_) {}),
          ],
        ),
        theme: tema,
      );
      api
        ..avisos = [reminderNotice]
        ..unread = 1;
      await tester.runAsync(avisos.load);
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });

    testWidgets('el Home con la campana cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      final api = FakeApi()
        ..avisos = [confirmationNotice, alertNotice]
        ..unread = 2;
      await mountUser(
        tester,
        dark: oscuro,
        start: '/inicio',
        api: api.cliente,
        center: (sesion) => centerOf(api, sesion),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }
}
