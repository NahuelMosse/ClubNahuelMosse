import 'dart:async';

import 'package:clubnahuelmosse/features/notifications/domain/notification_kind.dart';
import 'package:clubnahuelmosse/features/notifications/domain/notification_system.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notifications_spanish_test.dart'
    show ApiFalsa, SistemaFalso, centroDe, notif, recordatorio, ahoraClub;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _booking1 = '00000000-0000-7000-8000-000000000001';
const _booking2 = '00000000-0000-7000-8000-000000000002';
const _idRecordatorio = '00000000-0000-7000-8000-000000000003';

/// Un sistema donde el test decide cuándo la persona toca un aviso de la bandeja.
class SistemaConToques extends SistemaFalso {
  final toques = StreamController<NoticeTapped>.broadcast();

  @override
  Stream<NoticeTapped> get onTap => toques.stream;
}

Future<(ApiFalsa, NotificationCenter)> _abrirCentro(
  WidgetTester tester, {
  required List<String> avisos,
}) async {
  final api = ApiFalsa()
    ..avisos = avisos
    ..unread = avisos.length;
  final session = SesionFalsa(perfilUsuario);
  final centro = centroDe(api, session);
  await montar(
    tester,
    NotificationsScreen(
      center: centro,
      session: session,
      now: () => ahoraClub,
      onOpen: (_, _) {},
    ),
    tema: darkTheme,
  );
  return (api, centro);
}

/// La app entera con [avisos] sin leer y un sistema donde el test toca los avisos.
Future<(ApiFalsa, SistemaConToques, NotificationCenter)> _montarApp(
  WidgetTester tester,
  List<String> avisos,
) async {
  final api = ApiFalsa()
    ..avisos = avisos
    ..unread = avisos.length;
  final sistema = SistemaConToques();
  addTearDown(sistema.toques.close);
  late NotificationCenter centro;
  await montarUsuario(
    tester,
    inicio: '/inicio',
    api: api.cliente,
    centro: (session) => centro = centroDe(api, session, sistema: sistema),
  );
  return (api, sistema, centro);
}

Future<void> _salir(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(cargarFuentes);

  group('salir del centro de notificaciones', () {
    testWidgets(
      'abrir la campana y volver deja leídas las que se mostraron y la campana en cero @NOT-03-S1',
      (tester) async {
        final (api, centro) = await _abrirCentro(
          tester,
          avisos: [recordatorio],
        );
        expect(centro.unread, 1);

        await _salir(tester);

        expect(api.de('POST', '/notificaciones/leer-todas'), hasLength(1));
        expect(centro.unread, 0);
        expect(centro.list.every((n) => n.read), isTrue);
      },
    );

    testWidgets(
      'con el centro abierto las nuevas siguen marcadas sin leer @NOT-03-S1',
      (tester) async {
        final semantica = tester.ensureSemantics();
        final (api, centro) = await _abrirCentro(
          tester,
          avisos: [recordatorio],
        );

        expect(find.bySemanticsLabel(RegExp('sin leer')), findsOneWidget);
        expect(centro.unread, 1);
        expect(api.de('POST', '/notificaciones/leer-todas'), isEmpty);
        semantica.dispose();
      },
    );

    testWidgets(
      'si la API no contesta al salir se ven leídas y la próxima lectura corrige @assumption:NOT-03-ASM-02',
      (tester) async {
        final (api, centro) = await _abrirCentro(
          tester,
          avisos: [recordatorio],
        );
        api.caida = true;

        await _salir(tester);

        expect(centro.unread, 0);
        expect(centro.list.every((n) => n.read), isTrue);

        api.caida = false;
        await tester.runAsync(centro.load);
        expect(centro.unread, 1);
      },
    );
  });

  group('tocar un push', () {
    testWidgets(
      'tocar un push marca leídas las de ese tipo y reserva y abre la reserva @NOT-03-S2',
      (tester) async {
        final otherBooking = notif(
          id: '00000000-0000-7000-8000-000000000005',
          club: DateTime.utc(2026, 11, 12, 19, 50),
          reservaId: _booking2,
        );
        final otroTipo = notif(
          id: '00000000-0000-7000-8000-000000000006',
          club: DateTime.utc(2026, 11, 12, 19, 40),
          tipo: 'cancelacion_usuario',
          titulo: 'Reserva cancelada',
        );
        final (api, sistema, centro) = await _montarApp(tester, [
          recordatorio,
          otherBooking,
          otroTipo,
        ]);

        sistema.toques.add(
          NoticeTapped(kind: NotificationKind.reminder, bookingId: _booking1),
        );
        await tester.pumpAndSettle();

        final leidas = api.requests
            .where((p) => p.method == 'POST' && p.url.path.endsWith('/leer'))
            .map((p) => p.url.path)
            .toList();
        expect(leidas, ['/notificaciones/$_idRecordatorio/leer']);
        expect(centro.unreadList, hasLength(2));
        expect(find.text('Mis reservas'), findsOneWidget);
      },
    );

    testWidgets(
      'un push que no se toca sigue sin leer @assumption:NOT-03-ASM-01',
      (tester) async {
        final (api, _, centro) = await _montarApp(tester, [recordatorio]);

        expect(centro.unread, 1);
        expect(
          api.de('POST', '/notificaciones/$_idRecordatorio/leer'),
          isEmpty,
        );
        expect(api.de('POST', '/notificaciones/leer-todas'), isEmpty);
      },
    );
  });
}
