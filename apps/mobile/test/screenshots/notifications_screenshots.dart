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

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(loadFonts);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'dark': true, 'light': false};

  Future<void> capturar(WidgetTester tester, String archivo) async {
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));
  }

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: oscuro) in modos.entries) {
      Future<void> centro(
        WidgetTester tester, {
        List<String> avisos = const [],
        int unread = 0,
        bool permiso = true,
        double escala = 1,
      }) async {
        final api = FakeApi()
          ..avisos = avisos
          ..unread = unread;
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
          tema: oscuro ? darkTheme : lightTheme,
          tamano: tamano,
          escalaTexto: escala,
        );
      }

      testWidgets('centro $ancho $modo', (tester) async {
        await centro(
          tester,
          avisos: [reminderNotice, confirmationNotice, alertNotice],
          unread: 1,
        );
        await capturar(tester, 'notifications/center_${ancho}_$modo.png');
      });

      testWidgets('centro con el texto al 200 % $ancho $modo', (tester) async {
        await centro(
          tester,
          avisos: [reminderNotice, confirmationNotice, alertNotice],
          unread: 1,
          escala: 2,
        );
        await capturar(tester, 'notifications/center_200_${ancho}_$modo.png');
      });

      testWidgets('centro vacío $ancho $modo', (tester) async {
        await centro(tester);
        await capturar(tester, 'notifications/empty_${ancho}_$modo.png');
      });

      testWidgets('notificaciones desactivadas $ancho $modo', (tester) async {
        await centro(tester, permiso: false);
        await capturar(
          tester,
          'notifications/disabled_${ancho}_$modo.png',
        );
      });

      testWidgets('desactivadas con avisos $ancho $modo', (tester) async {
        await centro(tester, avisos: [reminderNotice], unread: 1, permiso: false);
        await capturar(
          tester,
          'notifications/disabled_with_notices_${ancho}_$modo.png',
        );
      });

      testWidgets('home con la campana $ancho $modo', (tester) async {
        final api = FakeApi()
          ..avisos = [reminderNotice, confirmationNotice]
          ..unread = 2;
        await mountUser(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/inicio',
          api: api.cliente,
          centro: (sesion) => centerOf(api, sesion),
        );
        await capturar(tester, 'notifications/home_${ancho}_$modo.png');
      });

      testWidgets('panel con la app abierta $ancho $modo', (tester) async {
        final api = FakeApi();
        final centroDeAvisos = centerOf(api, FakeSession(userProfile));
        await mountScreen(
          tester,
          Stack(
            children: [
              const Scaffold(body: SizedBox.expand()),
              NoticePanel(
                center: centroDeAvisos,
                now: () => noticesNow,
                onOpen: (_) {},
              ),
            ],
          ),
          tema: oscuro ? darkTheme : lightTheme,
          tamano: tamano,
        );
        api
          ..avisos = [
            reminderNotice,
            confirmationNotice.replaceFirst('"read": true', '"read": false'),
            alertNotice.replaceFirst('"read": true', '"read": false'),
          ]
          ..unread = 3;
        await tester.runAsync(centroDeAvisos.load);
        await capturar(tester, 'notifications/panel_${ancho}_$modo.png');
      });
    }
  }
}
