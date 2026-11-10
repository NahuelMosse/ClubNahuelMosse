import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/avatar.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  /// What the admin panel (CU-14) needs so it does not fail on a real request.
  final apiWithAdminPanel = apiRoutes({
    'GET /bookings/all': (
      200,
      '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
          ' "counters": {"all": 0, "active": 0, "completed": 0,'
          ' "voided": 0}}',
    ),
  });

  /// The real app with a session already started, launching at [start].
  Future<GoRouter> mountApp(
    WidgetTester tester,
    FakeSession session, {
    String start = '/home',
  }) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: start.startsWith('/admin') ? apiWithAdminPanel : homeApi(),
        session: session,
        appearance: Appearance.inMemory(),
        initialLocation: start,
      ),
    );
    await tester.pumpAndSettle();
    return GoRouter.of(tester.element(find.byType(Scaffold).first));
  }

  Future<void> openCard(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Tu cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets('the user card shows their data and their three options', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountApp(tester, FakeSession(userProfile));
    await openCard(tester);

    expect(find.text('Nahuel Mosse'), findsOneWidget);
    expect(find.text('nmosse@unimoron.edu.ar'), findsOneWidget);
    expect(find.text('MIEMBRO ACTIVO'), findsOneWidget);
    for (final option in ['Perfil completo', 'Mis reservas', 'Cerrar sesión']) {
      expect(find.text(option), findsOneWidget, reason: option);
    }
    semantics.dispose();
  });

  testWidgets(
    '«Perfil completo» and «Mis reservas» close the card and lead to their screen',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final routes = await mountApp(tester, FakeSession(userProfile));

      await openCard(tester);
      await tester.tap(find.text('Perfil completo'));
      await tester.pumpAndSettle();
      expect(find.text('CERRAR SESIÓN'), findsOneWidget);
      expect(find.text('Cerrar sesión'), findsNothing);

      routes.go('/home');
      await tester.pumpAndSettle();
      await openCard(tester);
      await tester.tap(find.text('Mis reservas'));
      await tester.pumpAndSettle();
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text('Próximas'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('signing out from the card returns to the login', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = FakeSession(userProfile);
    await mountApp(tester, session);

    await openCard(tester);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(session.closes, 1);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the administrator only has «Cerrar sesión» on their card', (
    tester,
  ) async {
    // Verifies CU-02-SUP-02.
    final semantics = tester.ensureSemantics();
    await mountApp(tester, FakeSession(adminProfile), start: '/admin');
    await openCard(tester);

    expect(find.text('Ana Díaz'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.text('Perfil completo'), findsNothing);
    expect(find.text('Mis reservas'), findsNothing);
    expect(find.text('MIEMBRO ACTIVO'), findsNothing);
    semantics.dispose();
  });

  testWidgets('tapping outside closes the card without signing out', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final session = FakeSession(userProfile);
    await mountApp(tester, session);
    await openCard(tester);

    await tester.tapAt(const Offset(40, 700));
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsNothing);
    expect(session.closes, 0);
    semantics.dispose();
  });

  testWidgets('«CERRAR SESIÓN» on My profile signs out', (tester) async {
    final semantics = tester.ensureSemantics();
    final session = FakeSession(userProfile);
    await mountScreen(
      tester,
      MyProfileScreen(session: session, appearance: Appearance.inMemory()),
      theme: darkTheme,
    );

    await tester.ensureVisible(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CERRAR SESIÓN'));
    await tester.pump();

    expect(session.closes, 1);
    semantics.dispose();
  });

  test(
    'the initials come from the first letter of the first and last name',
    () {
      expect(AvatarInitials.initials('Nahuel Agustín', 'Mosse'), 'NM');
      expect(AvatarInitials.initials(' ángel ', 'ñandú'), 'ÁÑ');
      expect(AvatarInitials.initials('Ana', ''), 'A');
    },
  );

  testWidgets('the avatar also opens with the screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountApp(tester, FakeSession(userProfile));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Tu cuenta')),
      matchesSemantics(label: 'Tu cuenta', isButton: true, hasTapAction: true),
    );
    semantics.dispose();
  });

  testWidgets('from «Perfil completo», back returns to the home', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountApp(tester, FakeSession(userProfile));
    await openCard(tester);
    await tester.tap(find.text('Perfil completo'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('signing out from the stacked My profile returns to the login', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await mountApp(tester, FakeSession(userProfile));
    await openCard(tester);
    await tester.tap(find.text('Perfil completo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CERRAR SESIÓN'));
    await tester.pumpAndSettle();
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('each role only enters its own screens', (tester) async {
    final user = await mountApp(tester, FakeSession(userProfile));
    user.go('/admin');
    await tester.pumpAndSettle();
    // Through a deep link, without the administrator role it sees «Acceso denegado» (CU-14 FA4).
    expect(find.text('Acceso denegado'), findsOneWidget);
    await tester.tap(find.text('IR A MIS RESERVAS'));
    await tester.pumpAndSettle();
    expect(find.text('PANEL ADMIN'), findsNothing);

    final admin = await mountApp(
      tester,
      FakeSession(adminProfile),
      start: '/admin',
    );
    admin.go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('PANEL ADMIN'), findsOneWidget);
  });
}
