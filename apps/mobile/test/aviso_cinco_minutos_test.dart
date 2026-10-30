import 'package:clubnahuelmosse/features/notifications/domain/app_notification.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notice_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _reserva = '00000000-0000-7000-8000-000000000007';

AppNotification _aviso(String tipo) => AppNotification.fromJson({
  'id': '00000000-0000-7000-8000-000000000001',
  'kind': tipo,
  'title': 'Tu reserva empieza en 5 minutos',
  'body': 'Fútbol 5 · Sede Morón · 21:00 – 22:00',
  'booking_id': _reserva,
  'created_at': '2026-11-12T23:55:00Z',
  'read': false,
})!;

void main() {
  testWidgets(
    'el aviso de 5 minutos se muestra con el ícono del recordatorio y abre la reserva @NOT-05-S2',
    (tester) async {
      final cinco = _aviso('five_minute_reminder');
      expect(cinco.kind, NotificationKind.fiveMinuteReminder);
      expect(
        noticeRoute(cinco.kind, cinco.bookingId),
        noticeRoute(NotificationKind.reminder, _reserva),
      );
      var toques = 0;
      await montar(
        tester,
        Scaffold(
          body: NoticeCard(
            notification: cinco,
            now: DateTime.utc(2026, 11, 12, 20),
            onTap: () => toques++,
          ),
        ),
        tema: lightTheme,
      );
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      await tester.tap(find.byType(NoticeCard));
      expect(toques, 1);
    },
  );
}
