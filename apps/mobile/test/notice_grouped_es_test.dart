import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_spanish_test.dart'
    show FakeApi, noticesNow, centerOf, noticeJson;
import 'support/mount.dart';

final readNotice = noticeJson(
  id: '00000000-0000-7000-8000-000000000005',
  club: DateTime.utc(2026, 11, 12, 19, 50),
  kind: 'forced_cancellation',
  title: 'El club anuló tu reserva',
  body: 'Fútbol 5 · Sede Morón · Mié 11, 20:00. Motivo: lluvia.',
  bookingId: '00000000-0000-7000-8000-000000000002',
  read: true,
);

final groupedNotice = noticeJson(
  id: '00000000-0000-7000-8000-000000000006',
  club: DateTime.utc(2026, 11, 12, 19, 59),
  kind: 'forced_cancellation',
  title: 'El club anuló 2 de tus reservas',
  body:
      'Tenés 2 reservas anuladas por el club. Mirá el detalle en tu historial.',
  bookingId: null,
);

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'a grouped voiding with another id reopens the panel while the app is open @assumption:CU-24.2-SUP-02',
    (tester) async {
      final api = FakeApi()
        ..notices = [readNotice]
        ..unread = 0;
      final session = FakeSession(userProfile);
      final NotificationCenter center = centerOf(api, session)
        ..location = () => '/inicio';
      await mountScreen(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(center: center, now: () => noticesNow, onOpen: (_) {}),
          ],
        ),
        theme: darkTheme,
      );
      await tester.runAsync(center.load);
      await tester.pumpAndSettle();
      expect(find.text('MARCAR TODAS'), findsNothing);

      api
        ..notices = [groupedNotice, readNotice]
        ..unread = 1;
      await tester.runAsync(center.load);
      await tester.pumpAndSettle();

      expect(find.text('El club anuló 2 de tus reservas'), findsOneWidget);
      expect(center.unread, 1);
    },
  );
}
