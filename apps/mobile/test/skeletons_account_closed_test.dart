import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/bottom_bar.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/features/notifications/data/notifications_repository.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/profile_card.dart';
import 'package:clubnahuelmosse/features/users/presentation/profile_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'notificaciones_test.dart' show SistemaFalso, confirmacion, recordatorio;
import 'soporte/admin.dart';
import 'soporte/held_api.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

/// Un perfil cuya lectura espera a [release]: Mi perfil queda cargando.
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

const _skeletonCard = ValueKey('skeleton-card');
const _skeletonHeader = ValueKey('skeleton-header');

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

Future<void> _open(
  WidgetTester tester,
  HeldApi api,
  String route, {
  Session? session,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
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

/// Desmonta y deja pasar el límite de espera del cliente para que no quede un Timer.
Future<void> _close(WidgetTester tester, HeldApi api) async {
  await tester.pumpWidget(const SizedBox());
  api.release();
  await tester.pump(const Duration(minutes: 2));
}

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'Mi perfil carga con skeleton de su cabecera y sus datos, no un spinner @VIS-03-S2',
    (tester) async {
      final api = HeldApi({});
      final session = _HeldSession();
      await _open(tester, api, '/perfil', session: session);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Skeleton), findsWidgets);
      expect(find.byType(BottomBar), findsOneWidget);
      final header = tester.getRect(find.byKey(_skeletonHeader));
      final cards = [
        for (final e in find.byKey(_skeletonCard).evaluate())
          tester.getRect(find.byWidget(e.widget)),
      ];
      expect(cards, hasLength(3));

      session.release();
      await tester.pumpAndSettle();

      expect(find.byType(Skeleton), findsNothing);
      expectSameBox(
        header,
        tester.getRect(find.byType(ProfileHeader)),
        edge: 2,
      );
      final real = find.byType(ProfileCard);
      for (var i = 0; i < 3; i++) {
        expectSameBox(cards[i], tester.getRect(real.at(i)), edge: 2);
      }
      await _close(tester, api);
    },
  );

  testWidgets(
    'los skeletons de cuenta brillan, se detienen con reducir movimiento y dicen Cargando una vez @assumption:VIS-03-ASM-05 @VIS-03-ASM-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final screens = <(String, HeldApi, Session?)>[
        ('/inicio', HeldApi(_homeAnswers), null),
        (
          '/notificaciones',
          HeldApi(_noticeAnswers, held: {'GET /notificaciones'}),
          null,
        ),
        ('/perfil', HeldApi({}), _HeldSession()),
      ];

      for (final (route, api, session) in screens) {
        await _open(tester, api, route, session: session);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.hasRunningAnimations, isTrue, reason: '$route brilla');
        expect(
          find.bySemanticsLabel('Cargando'),
          findsOneWidget,
          reason: route,
        );
        await _close(tester, api);
      }

      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      for (final (route, api, session) in screens) {
        api.holdAgain();
        await _open(tester, api, route, session: session);
        await tester.pump(const Duration(seconds: 3));
        expect(find.byType(Skeleton), findsWidgets, reason: route);
        expect(tester.hasRunningAnimations, isFalse, reason: '$route quieto');
        expect(
          find.bySemanticsLabel('Cargando'),
          findsOneWidget,
          reason: route,
        );
        await _close(tester, api);
      }
      semantics.dispose();
    },
  );
}
