import 'package:clubnahuelmosse/common/app_language.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_background.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

const _screenSize = Size(393, 852);
const _keyboardHeight = 300.0;
const _aboveKeyboard = 852.0 - _keyboardHeight;

void main() {
  setUpAll(loadFonts);

  Future<void> mountLogin(
    WidgetTester tester, {
    FakeCredentials? credentials,
  }) async {
    tester.view.physicalSize = _screenSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        localeListResolutionCallback: resolveLanguage,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LoginScreen(
          session: Session(
            repository: SessionRepository(
              credentials: credentials ?? FakeCredentials(),
              api: fakeApi(status: 200, body: profileJson()),
            ),
          ),
          pending: PendingBooking(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openKeyboard(WidgetTester tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardHeight * 3);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'with the keyboard open the login photo takes up the same area @SES-01-S1 @assumption:SES-01-ASM-01',
    (tester) async {
      await mountLogin(tester);
      final closed = tester.getRect(find.byType(LoginBackground));

      await openKeyboard(tester);

      expect(tester.getRect(find.byType(LoginBackground)), closed);
    },
  );

  testWidgets(
    'with the keyboard open the sign-in button is reached by scrolling @SES-01-S2',
    (tester) async {
      await mountLogin(tester);
      await openKeyboard(tester);

      await tester.ensureVisible(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('INICIAR SESIÓN')).bottom,
        lessThanOrEqualTo(_aboveKeyboard),
      );
    },
  );

  testWidgets(
    'with the keyboard open the invalid credentials notice stays above the keyboard @assumption:SES-01-ASM-02',
    (tester) async {
      await mountLogin(
        tester,
        credentials: FakeCredentials(
          onSignIn: (_, _) async => throw const InvalidCredentials(),
        ),
      );
      await tester.enterText(find.bySemanticsLabel('Correo'), 'a@correo.com');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
      await openKeyboard(tester);

      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(find.text(invalidCredentialsMessage), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Cerrar aviso')).bottom,
        lessThanOrEqualTo(_aboveKeyboard),
      );
    },
  );
}
