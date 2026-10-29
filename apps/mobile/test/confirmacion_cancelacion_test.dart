import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notificaciones_test.dart'
    show ApiFalsa, ahoraClub, centroDe, notif, recordatorio;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

final cancelada = notif(
  id: '00000000-0000-7000-8000-000000000005',
  club: DateTime.utc(2026, 11, 12, 19, 59),
  tipo: 'user_cancellation',
  titulo: 'Reserva cancelada',
  cuerpo: 'Fútbol 5 · Sede Morón · Mié 11, 20:00. El horario quedó liberado.',
  reservaId: '00000000-0000-7000-8000-000000000002',
);

void main() {
  setUpAll(cargarFuentes);

  group('la confirmación de una cancelación en el panel', () {
    Future<(ApiFalsa, NotificationCenter)> abrir(
      WidgetTester tester, {
      required String ubicacion,
      Size tamano = const Size(393, 852),
      double escala = 1,
    }) async {
      final api = ApiFalsa();
      final sesion = SesionFalsa(perfilUsuario);
      final centro = centroDe(api, sesion)..location = () => ubicacion;
      await montar(
        tester,
        Stack(
          children: [
            const Scaffold(body: Center(child: Text('la pantalla de abajo'))),
            NoticePanel(center: centro, now: () => ahoraClub, onOpen: (_) {}),
          ],
        ),
        tema: darkTheme,
        tamano: tamano,
        escalaTexto: escala,
      );
      return (api, centro);
    }

    Future<void> llega(
      WidgetTester tester,
      ApiFalsa api,
      NotificationCenter centro,
      List<String> avisos,
    ) async {
      api
        ..avisos = avisos
        ..unread = avisos.length;
      await tester.runAsync(centro.load);
      await tester.pumpAndSettle();
    }

    testWidgets('fuera de Mis reservas abre el panel con el aviso', (
      tester,
    ) async {
      final (api, centro) = await abrir(tester, ubicacion: '/inicio');

      await llega(tester, api, centro, [cancelada]);

      expect(find.text('Reserva cancelada'), findsOneWidget);
      expect(
        find.text(
          'Fútbol 5 · Sede Morón · Mié 11, 20:00. El horario quedó liberado.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'en Mis reservas no abre el panel pero cuenta como sin leer @supuesto:CU-24.3-SUP-03',
      (tester) async {
        final (api, centro) = await abrir(tester, ubicacion: '/reservas');

        await llega(tester, api, centro, [cancelada]);

        expect(find.text('MARCAR TODAS'), findsNothing);
        expect(find.text('Reserva cancelada'), findsNothing);
        expect(centro.unread, 1);
        expect(centro.list.single.read, isFalse);
      },
    );

    testWidgets(
      'lo silenciado no vuelve al panel cuando llega otro aviso @supuesto:CU-24.3-SUP-07',
      (tester) async {
        final (api, centro) = await abrir(tester, ubicacion: '/reservas');
        await llega(tester, api, centro, [cancelada]);

        await llega(tester, api, centro, [
          recordatorio.replaceFirst(
            '"id": "00000000-0000-7000-8000-000000000003"',
            '"id": "00000000-0000-7000-8000-000000000006"',
          ),
          cancelada,
        ]);

        expect(find.text('Tu reserva es en 1 hora'), findsOneWidget);
        expect(find.text('Reserva cancelada'), findsNothing);
        expect(centro.unread, 2);
      },
    );

    for (final ancho in [360.0, 430.0]) {
      testWidgets(
        'con el texto al 200 % en ${ancho.toInt()} de ancho entra en pantalla',
        (tester) async {
          final (api, centro) = await abrir(
            tester,
            ubicacion: '/inicio',
            tamano: Size(ancho, 800),
            escala: 2,
          );

          await llega(tester, api, centro, [cancelada]);

          expect(tester.takeException(), isNull);
          expect(find.text('Reserva cancelada'), findsOneWidget);
          expect(
            tester.getBottomRight(find.text('MARCAR TODAS')).dx,
            lessThanOrEqualTo(ancho),
          );
        },
      );
    }
  });

  group('al tocar la confirmación', () {
    testWidgets('abre Mis reservas en el historial @supuesto:CU-24.3-SUP-06', (
      tester,
    ) async {
      final api = ApiFalsa()
        ..avisos = [cancelada]
        ..unread = 1;
      await montarUsuario(
        tester,
        inicio: '/notificaciones',
        api: api.cliente,
        centro: (sesion) => centroDe(api, sesion),
      );
      api.pedidos.clear();

      await tester.tap(find.text('Reserva cancelada'));
      await tester.pumpAndSettle();

      expect(find.text('Mis reservas'), findsOneWidget);
      expect(
        api.de('GET', '/bookings').map((p) => p.url.queryParameters['when']),
        ['history'],
      );
    });

    testWidgets('un recordatorio sigue abriendo las próximas', (tester) async {
      final api = ApiFalsa()
        ..avisos = [recordatorio]
        ..unread = 1;
      await montarUsuario(
        tester,
        inicio: '/notificaciones',
        api: api.cliente,
        centro: (sesion) => centroDe(api, sesion),
      );
      api.pedidos.clear();

      await tester.tap(find.text('Tu reserva es en 1 hora'));
      await tester.pumpAndSettle();

      expect(
        api.de('GET', '/bookings').map((p) => p.url.queryParameters['when']),
        ['upcoming'],
      );
    });
  });
}
