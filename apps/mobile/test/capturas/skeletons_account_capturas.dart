import 'dart:async';

import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mis_reservas_test.dart' show reservaJson;
import '../notificaciones_test.dart'
    show SistemaFalso, confirmacion, recordatorio;
import '../soporte/admin.dart';
import '../soporte/held_api.dart';
import '../soporte/montar.dart';
import '../soporte/usuario.dart';

/// A profile whose read waits for [release]: My profile stays loading.
class _HeldSession extends SesionFalsa {
  _HeldSession() : super(perfilUsuario);

  final _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<Profile> refresh() async {
    await _gate.future;
    return super.refresh();
  }
}

final _homeAnswers = {
  'GET /reservas': (200, '{"reservas": [${reservaJson()}]}'),
  'GET /espacios/catalogo': (200, catalogoJson),
  'GET /sedes': (200, '{"sedes": [$sedeMoronConDeportes]}'),
};

final _noticeAnswers = {
  'GET /notificaciones': (
    200,
    '{"notificaciones": [$recordatorio, $confirmacion], "no_leidas": 1}',
  ),
};

/// Asserts nothing: it produces each loading state of the account screens next to the same
/// screen loaded, dark, 393x852.
void main() {
  Future<void> mount(
    WidgetTester tester,
    HeldApi api,
    String route, {
    Session? session,
  }) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await cargarFuentes();
    final current = session ?? SesionFalsa(perfilUsuario);
    await tester.pumpWidget(
      App(
        api: api.client,
        session: current,
        appearance: Appearance.inMemory(dark: true),
        notificationCenter: NotificationCenter(
          notifications: NotificationsRepository(
            api: api.client,
            session: current,
          ),
          session: current,
          system: SistemaFalso(),
          every: Duration.zero,
          now: () => DateTime.utc(2026, 11, 13),
        ),
        initialLocation: route,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> capture(WidgetTester tester, String file) async {
    await tester.pump();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('home loading and loaded', (tester) async {
    final api = HeldApi(_homeAnswers);
    await mount(tester, api, '/inicio');
    await capture(tester, 'skeletons/inicio_cargando.png');
    api.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/inicio_cargada.png');
    await drain(tester);
  });

  testWidgets('notifications loading and loaded', (tester) async {
    final api = HeldApi(_noticeAnswers, held: {'GET /notificaciones'});
    await mount(tester, api, '/notificaciones');
    await capture(tester, 'skeletons/notificaciones_cargando.png');
    api.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/notificaciones_cargada.png');
    await drain(tester);
  });

  testWidgets('profile loading and loaded', (tester) async {
    final api = HeldApi({});
    final session = _HeldSession();
    await mount(tester, api, '/perfil', session: session);
    await capture(tester, 'skeletons/perfil_cargando.png');
    session.release();
    await tester.pumpAndSettle();
    await capture(tester, 'skeletons/perfil_cargada.png');
    await drain(tester);
  });
}
