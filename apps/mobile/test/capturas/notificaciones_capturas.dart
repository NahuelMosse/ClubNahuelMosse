import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../notificaciones_test.dart'
    show
        ApiFalsa,
        SistemaFalso,
        ahoraClub,
        alerta,
        centroDe,
        confirmacion,
        recordatorio;
import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';
import '../soporte/usuario.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(cargarFuentes);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  const modos = {'oscuro': true, 'claro': false};

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
        final api = ApiFalsa()
          ..avisos = avisos
          ..unread = unread;
        final sesion = SesionFalsa(perfilUsuario);
        await montar(
          tester,
          NotificationsScreen(
            center: centroDe(
              api,
              sesion,
              sistema: SistemaFalso(concedido: permiso),
            ),
            session: sesion,
            now: () => ahoraClub,
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
          avisos: [recordatorio, confirmacion, alerta],
          unread: 1,
        );
        await capturar(tester, 'notificaciones/centro_${ancho}_$modo.png');
      });

      testWidgets('centro con el texto al 200 % $ancho $modo', (tester) async {
        await centro(
          tester,
          avisos: [recordatorio, confirmacion, alerta],
          unread: 1,
          escala: 2,
        );
        await capturar(tester, 'notificaciones/centro_200_${ancho}_$modo.png');
      });

      testWidgets('centro vacío $ancho $modo', (tester) async {
        await centro(tester);
        await capturar(tester, 'notificaciones/vacio_${ancho}_$modo.png');
      });

      testWidgets('notificaciones desactivadas $ancho $modo', (tester) async {
        await centro(tester, permiso: false);
        await capturar(
          tester,
          'notificaciones/desactivadas_${ancho}_$modo.png',
        );
      });

      testWidgets('desactivadas con avisos $ancho $modo', (tester) async {
        await centro(tester, avisos: [recordatorio], unread: 1, permiso: false);
        await capturar(
          tester,
          'notificaciones/desactivadas_con_avisos_${ancho}_$modo.png',
        );
      });

      testWidgets('home con la campana $ancho $modo', (tester) async {
        final api = ApiFalsa()
          ..avisos = [recordatorio, confirmacion]
          ..unread = 2;
        await montarUsuario(
          tester,
          oscuro: oscuro,
          tamano: tamano,
          inicio: '/inicio',
          api: api.cliente,
          centro: (sesion) => centroDe(api, sesion),
        );
        await capturar(tester, 'notificaciones/home_${ancho}_$modo.png');
      });

      testWidgets('panel con la app abierta $ancho $modo', (tester) async {
        final api = ApiFalsa();
        final centroDeAvisos = centroDe(api, SesionFalsa(perfilUsuario));
        await montar(
          tester,
          Stack(
            children: [
              const Scaffold(body: SizedBox.expand()),
              NoticePanel(
                center: centroDeAvisos,
                now: () => ahoraClub,
                onOpen: (_) {},
              ),
            ],
          ),
          tema: oscuro ? darkTheme : lightTheme,
          tamano: tamano,
        );
        api
          ..avisos = [
            recordatorio,
            confirmacion.replaceFirst('"leida": true', '"leida": false'),
            alerta.replaceFirst('"leida": true', '"leida": false'),
          ]
          ..unread = 3;
        await tester.runAsync(centroDeAvisos.load);
        await capturar(tester, 'notificaciones/panel_${ancho}_$modo.png');
      });
    }
  }
}
