import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_spanish_test.dart'
    show ApiFalsa, ahoraClub, centroDe, notif;
import 'soporte/montar.dart';

final leida = notif(
  id: '00000000-0000-7000-8000-000000000005',
  club: DateTime.utc(2026, 11, 12, 19, 50),
  tipo: 'cancelacion_forzosa',
  titulo: 'El club anuló tu reserva',
  cuerpo: 'Fútbol 5 · Sede Morón · Mié 11, 20:00. Motivo: lluvia.',
  reservaId: '00000000-0000-7000-8000-000000000002',
  leida: true,
);

final agrupado = notif(
  id: '00000000-0000-7000-8000-000000000006',
  club: DateTime.utc(2026, 11, 12, 19, 59),
  tipo: 'cancelacion_forzosa',
  titulo: 'El club anuló 2 de tus reservas',
  cuerpo:
      'Tenés 2 reservas anuladas por el club. Mirá el detalle en tu historial.',
  reservaId: null,
);

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'una anulación agrupada con otro id reabre el panel con la app abierta @supuesto:CU-24.2-SUP-02',
    (tester) async {
      final api = ApiFalsa()
        ..avisos = [leida]
        ..unread = 0;
      final session = SesionFalsa(perfilUsuario);
      final NotificationCenter centro = centroDe(api, session)
        ..location = () => '/inicio';
      await montar(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(center: centro, now: () => ahoraClub, onOpen: (_) {}),
          ],
        ),
        tema: darkTheme,
      );
      await tester.runAsync(centro.load);
      await tester.pumpAndSettle();
      expect(find.text('MARCAR TODAS'), findsNothing);

      api
        ..avisos = [agrupado, leida]
        ..unread = 1;
      await tester.runAsync(centro.load);
      await tester.pumpAndSettle();

      expect(find.text('El club anuló 2 de tus reservas'), findsOneWidget);
      expect(centro.unread, 1);
    },
  );
}
