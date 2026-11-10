import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';
import 'package:clubnahuelmosse/features/session/data/password_recovery.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/new_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

void main() {
  setUpAll(loadFonts);

  Widget login({bool rejects = false}) => LoginScreen(
    pending: PendingBooking(),
    session: Session(
      repository: SessionRepository(
        credentials: FakeCredentials(
          onSignIn: rejects
              ? (_, _) async => throw const InvalidCredentials()
              : null,
        ),
        api: fakeApi(status: 200, body: profileJson()),
      ),
    ),
  );

  Future<void> meetsGuidelines(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final themes = {'dark': darkTheme, 'light': lightTheme};
  final screens = <String, Widget Function()>{
    'the login': login,
    'the Home': () => fakeHome(FakeSession(userProfile)),
    'the admin panel': () {
      final session = FakeSession(adminProfile);
      final api = apiRoutes({
        'GET /bookings/all': (
          200,
          '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
              ' "counters": {"all": 0, "active": 0, "completed": 0,'
              ' "voided": 0}}',
        ),
      });
      return AdminPanelScreen(
        history: BookingHistory(api: api, sesion: session),
        venues: Venues(
          repository: VenuesRepository(api: api, session: session),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: session),
        ),
        session: session,
        pending: PendingPanelFilters(),
      );
    },
    'password recovery': () => ForgotPasswordScreen(
      recovery: PasswordRecovery(fakeApi(status: 202, body: '')),
    ),
    'My profile': () => MyProfileScreen(
      session: FakeSession(userProfile),
      appearance: Appearance.inMemory(),
    ),
    'the new password': () => NewPasswordScreen(
      recovery: PasswordRecovery(fakeApi(status: 204, body: '')),
      session: FakeSession(null),
      code: 'abc',
    ),
    'the invalid link': () => NewPasswordScreen(
      recovery: PasswordRecovery(fakeApi(status: 410, body: '')),
      session: FakeSession(null),
      code: 'abc',
    ),
    'change password': () =>
        ChangePasswordScreen(session: FakeSession(userProfile)),
  };

  for (final MapEntry(key: mode, value: theme) in themes.entries) {
    for (final MapEntry(key: name, value: screen) in screens.entries) {
      testWidgets('$name meets the accessibility guidelines in $mode mode', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(tester, screen(), theme: theme);
        await meetsGuidelines(tester);
        semantics.dispose();
      });
    }

    testWidgets(
      'the login with errors and notice meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(tester, login(rejects: true), theme: theme);
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        await tester.enterText(find.bySemanticsLabel('Correo'), 'n@correo.com');
        await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        expect(find.text(invalidCredentialsMessage), findsOneWidget);
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );
  }

  for (final MapEntry(key: mode, value: theme) in themes.entries) {
    testWidgets('the profile being edited meets the guidelines in $mode mode', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await mountScreen(
        tester,
        MyProfileScreen(
          session: FakeSession(userProfile),
          appearance: Appearance.inMemory(),
        ),
        theme: theme,
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await meetsGuidelines(tester);
      semantics.dispose();
    });
  }

  for (final MapEntry(key: mode, value: theme) in themes.entries) {
    testWidgets(
      'the account deletion confirmation meets the guidelines in $mode mode',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          MyProfileScreen(
            session: FakeSession(userProfile),
            appearance: Appearance.inMemory(),
          ),
          theme: theme,
        );
        await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ELIMINAR CUENTA'));
        await tester.pumpAndSettle();
        await meetsGuidelines(tester);
        semantics.dispose();
      },
    );
  }

  testWidgets('the login fields announce their name', (tester) async {
    final semantics = tester.ensureSemantics();
    await mountScreen(tester, login(), theme: darkTheme);
    expect(find.bySemanticsLabel('Correo'), findsOneWidget);
    expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
    expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('with text at 200 % nothing overflows', (tester) async {
    for (final screen in screens.values) {
      await mountScreen(
        tester,
        screen(),
        theme: darkTheme,
        size: const Size(360, 800),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
