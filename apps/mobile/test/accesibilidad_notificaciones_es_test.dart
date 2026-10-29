import 'package:clubnahuelmosse/features/notifications/presentation/notice_panel.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notifications_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'notificaciones_es_test.dart'
    show
        ApiFalsa,
        SistemaFalso,
        ahoraClub,
        alerta,
        centroDe,
        confirmacion,
        recordatorio;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  setUpAll(cargarFuentes);

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
      final api = ApiFalsa()
        ..avisos = avisos
        ..unread = avisos.length;
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
        tema: tema,
      );
    }

    testWidgets('el centro con avisos cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await centro(tester, avisos: [recordatorio, confirmacion, alerta]);
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
      final api = ApiFalsa();
      final avisos = centroDe(api, SesionFalsa(perfilUsuario));
      await montar(
        tester,
        Stack(
          children: [
            const Scaffold(body: SizedBox.expand()),
            NoticePanel(center: avisos, now: () => ahoraClub, onOpen: (_) {}),
          ],
        ),
        tema: tema,
      );
      api
        ..avisos = [recordatorio]
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
      final api = ApiFalsa()
        ..avisos = [confirmacion, alerta]
        ..unread = 2;
      await montarUsuario(
        tester,
        oscuro: oscuro,
        inicio: '/inicio',
        api: api.cliente,
        centro: (sesion) => centroDe(api, sesion),
      );
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }
}
