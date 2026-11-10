import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/admin.dart';
import 'support/mount.dart';

/// The API always answering 403, as with a role that is no longer enough.
ApiClient _api403() => ApiClient(
  'http://api.falsa',
  client: MockClient((_) async => http.Response('{}', 403)),
);

/// A session that opened as an administrator and, on re-reading the profile, is now a user.
class _DowngradedSession extends FakeSession {
  _DowngradedSession() : super(adminProfile);

  int reads = 0;
  Profile? _downgraded;

  @override
  Profile? get profile => _downgraded ?? super.profile;

  @override
  Future<Profile> refresh() async {
    reads++;
    _downgraded = userProfile;
    notifyListeners();
    return userProfile;
  }
}

void main() {
  setUpAll(loadFonts);

  final notices = <String, (String, Future<void> Function(BuildContext))>{
    'error de conexión': (
      'REINTENTAR',
      (c) => showNetworkError(c, const NoConnection()),
    ),
    'error del servidor': (
      'ACEPTAR',
      (c) => showNetworkError(c, const ServerError(500)),
    ),
    'sesión expirada': ('IR AL INICIO DE SESIÓN', showSessionExpired),
    'esto cambió mientras tanto': ('VER LO ACTUALIZADO', showChangedMeanwhile),
  };

  for (final MapEntry(key: name, value: (button, open)) in notices.entries) {
    testWidgets('the «$name» notice fits at 360 with text at 200 %', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountScreen(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => open(context),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        theme: darkTheme,
        size: const Size(360, 800),
        textScale: 2,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(button));
      await tester.pumpAndSettle();
      expect(find.text(button), findsOneWidget);
      semantics.dispose();
    });
  }

  testWidgets('«Acceso denegado» fits at 360 with text at 200 %', (
    tester,
  ) async {
    await mountScreen(
      tester,
      AccessDeniedScreen(session: FakeSession(userProfile)),
      theme: darkTheme,
      size: const Size(360, 800),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('IR A MIS RESERVAS'), findsOneWidget);
  });

  testWidgets(
    'a user entering the panel sees «Acceso denegado» and reaches «Mis reservas»',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        App(
          api: apiRoutes({'GET /bookings': (200, '{"bookings": []}')}),
          session: FakeSession(userProfile),
          appearance: Appearance.inMemory(),
          initialLocation: '/admin',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
      expect(find.text('PANEL ADMIN'), findsNothing);
      await tester.tap(find.text('IR A MIS RESERVAS'));
      await tester.pumpAndSettle();
      expect(find.text('Acceso denegado'), findsNothing);
      expect(find.text('Mis reservas'), findsWidgets);
    },
  );

  testWidgets(
    'a downgraded administrator leaves «Acceso denegado» for «Mis reservas» without returning to the panel',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final session = _DowngradedSession();
      await tester.pumpWidget(
        App(
          api: ApiClient(
            'http://api.falsa',
            client: MockClient(
              (request) async => switch (request.url.path) {
                '/bookings' => http.Response('{"bookings": []}', 200),
                '/spaces/catalog' => http.Response(catalogJson, 200),
                _ => http.Response('{}', 403),
              },
            ),
          ),
          session: session,
          appearance: Appearance.inMemory(),
          initialLocation: '/admin/venues',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acceso denegado'), findsOneWidget);

      await tester.tap(find.text('IR A MIS RESERVAS'));
      await tester.pumpAndSettle();

      expect(session.reads, greaterThan(0));
      expect(find.text('Acceso denegado'), findsNothing);
      expect(find.text('PANEL ADMIN'), findsNothing);
      expect(find.text('Mis reservas'), findsWidgets);
    },
  );

  testWidgets('«Acceso denegado» offers to sign out', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = FakeSession(userProfile);
    await tester.pumpWidget(
      App(
        api: apiRoutes({}),
        session: session,
        appearance: Appearance.inMemory(),
        initialLocation: '/admin',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(session.closes, 1);
    expect(find.text('Acceso denegado'), findsNothing);
  });

  testWidgets(
    'a 403 when loading the space creation does not navigate over «Acceso denegado»',
    (tester) async {
      await mountAdmin(tester, api: _api403(), start: '/admin/spaces/new');
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
      expect(find.text('Error del servidor'), findsNothing);
    },
  );

  testWidgets(
    'a 403 when loading a venue does not navigate over «Acceso denegado»',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        App(
          api: _api403(),
          session: FakeSession(userProfile),
          appearance: Appearance.inMemory(),
          initialLocation: '/venues/00000000-0000-7000-8000-000000000001',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
    },
  );

  test(
    'an API that does not answer within the limit is treated as the server not responding',
    () async {
      final api = ApiClient(
        'http://api.falsa',
        limit: const Duration(milliseconds: 50),
        client: MockClient((_) => Completer<http.Response>().future),
      );

      await expectLater(
        api.get('/venues'),
        throwsA(isA<ServerNotResponding>()),
      );
    },
  );
}
