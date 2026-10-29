import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/session/data/password_recovery.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/new_password_screen.dart';
import 'package:clubnahuelmosse/features/users/data/registration_service.dart';
import 'package:clubnahuelmosse/features/users/domain/registration_rules.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/users/presentation/registration_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];
const _spanish = [Locale('es', 'AR')];

void main() {
  setUpAll(cargarFuentes);

  Future<void> mount(
    WidgetTester tester,
    List<Locale> device,
    Widget screen,
  ) async {
    tester.platformDispatcher.localesTestValue = device;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await montar(tester, screen, tema: darkTheme);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  RegistrationScreen registration() =>
      RegistrationScreen(registration: RegistrationService(apiFalsa()));

  testWidgets(
    'login, registration and password recovery show English @ENG-19-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mount(tester, _english, registration());
      expect(find.text('Sign up'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('All fields are required.'), findsOneWidget);
      for (final label in [
        'FIRST NAME',
        'LAST NAME',
        'DATE OF BIRTH',
        'EMAIL',
        'PASSWORD',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Your first name'), findsOneWidget);
      expect(find.text('DD / MM / YYYY'), findsOneWidget);
      expect(find.byTooltip('Pick a date'), findsOneWidget);
      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.text('CREAR CUENTA'), findsNothing);

      await mount(
        tester,
        _english,
        ForgotPasswordScreen(
          recovery: PasswordRecovery(apiFalsa(codigo: 202, cuerpo: '')),
        ),
      );
      expect(find.text('Recover password'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('SEND LINK'), findsOneWidget);
      await tester.enterText(find.bySemanticsLabel('Email'), 'ana@correo.com');
      await tap(tester, find.text('SEND LINK'));
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.text(
          'If the email is registered, we sent you a link to create a new '
          'password. The link expires in 30 minutes.',
        ),
        findsOneWidget,
      );
      expect(find.text('BACK TO SIGN IN'), findsOneWidget);

      await mount(
        tester,
        _english,
        NewPasswordScreen(
          recovery: PasswordRecovery(apiFalsa(codigo: 204, cuerpo: '')),
          session: SesionFalsa(null),
          code: 'abc',
        ),
      );
      expect(find.text('Create a new password'), findsOneWidget);
      expect(find.text('NEW PASSWORD'), findsOneWidget);
      expect(find.text('REPEAT PASSWORD'), findsOneWidget);

      await mount(
        tester,
        _english,
        NewPasswordScreen(
          recovery: PasswordRecovery(apiFalsa(codigo: 410, cuerpo: '')),
          session: SesionFalsa(null),
          code: 'abc',
        ),
      );
      expect(find.text('The link is not valid'), findsOneWidget);
      expect(find.text('REQUEST A NEW LINK'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'profile, edit profile, change password and account closure show English @ENG-19-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await mount(
        tester,
        _english,
        MyProfileScreen(
          session: SesionFalsa(perfilUsuario),
          appearance: Appearance.inMemory(),
        ),
      );
      for (final text in [
        'PERSONAL DETAILS',
        'Edit',
        'First name',
        'Last name',
        'Birth',
        'SECURITY',
        'Change password',
        'APPEARANCE',
        'Dark mode',
        'SIGN OUT',
        'DELETE ACCOUNT',
        'ACTIVE MEMBER',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
        find.bySemanticsLabel(
          'Email: nmosse@unimoron.edu.ar. Cannot be changed',
        ),
        findsOneWidget,
      );

      await tap(tester, find.text('Edit'));
      expect(find.text('DATE OF BIRTH'), findsOneWidget);
      expect(find.byTooltip('Choose the date in the calendar'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);

      await tap(tester, find.text('DELETE ACCOUNT'));
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(
        find.text(
          'This action is permanent. Your data and your active bookings will '
          'be deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('CANCEL'), findsOneWidget);

      await mount(
        tester,
        _english,
        ChangePasswordScreen(session: SesionFalsa(perfilUsuario)),
      );
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Change your password'), findsOneWidget);
      expect(
        find.text('We need your current password to confirm it is you.'),
        findsOneWidget,
      );
      expect(find.text('CURRENT PASSWORD'), findsOneWidget);
      expect(find.text('Your current password'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('the home shows English @ENG-19-S1', (tester) async {
    final semantics = tester.ensureSemantics();
    await mount(tester, _english, inicioFalso(SesionFalsa(perfilUsuario)));
    expect(
      find.textContaining(RegExp(r'^GOOD (MORNING|AFTERNOON|EVENING),$')),
      findsOneWidget,
    );
    expect(find.text('BOOK YOUR COURT'), findsOneWidget);
    for (final label in ['VENUES', 'COURTS', 'UPCOMING']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tap(tester, find.bySemanticsLabel('Your account'));
    expect(find.text('Full profile'), findsOneWidget);
    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tapAt(const Offset(10, 600));
    await tester.pumpAndSettle();
    expect(find.text('YOUR NEXT BOOKING'), findsOneWidget);
    expect(find.text('VIEW ALL →'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Find a court'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('QUICK ACCESS'), findsOneWidget);
    expect(find.text('By venue, date and time'), findsOneWidget);
    expect(find.text('View venues'), findsOneWidget);
    expect(find.text('Hours and courts of each one'), findsOneWidget);

    semantics.dispose();
  });

  testWidgets(
    'the registration and profile validations the domain decides show in English and in Spanish @ENG-19-ASM-05',
    (tester) async {
      // The domain decides what happened and returns it as a value, not as text.
      expect(validateEmail('a@b'), isNotNull);
      expect(validateEmail('a@b'), isNot(isA<String>()));
      expect(validateDni('123'), isNot(isA<String>()));
      expect(validatePassword(''), isNot(isA<String>()));
      expect(passwordProblems('abc'), everyElement(isNot(isA<String>())));

      final semantics = tester.ensureSemantics();
      for (final (device, create, messages) in [
        (
          _english,
          'CREATE ACCOUNT',
          [
            'First name is required',
            'Last name is required',
            'The DNI has 7 or 8 digits',
            'The date is not valid',
            'Check the email format',
            'At least 8 characters',
          ],
        ),
        (
          _spanish,
          'CREAR CUENTA',
          [
            'El nombre es obligatorio',
            'El apellido es obligatorio',
            'El DNI tiene 7 u 8 números',
            'La fecha no es válida',
            'Revisá el formato del correo',
            'Al menos 8 caracteres',
          ],
        ),
      ]) {
        await mount(tester, device, registration());
        final english = device == _english;
        await tester.enterText(find.bySemanticsLabel('DNI'), '123');
        await tester.enterText(
          find.bySemanticsLabel(
            english ? 'Date of birth' : 'Fecha de nacimiento',
          ),
          '30022000',
        );
        await tester.enterText(
          find.bySemanticsLabel(english ? 'Email' : 'Correo electrónico'),
          'ana',
        );
        await tester.enterText(
          find.bySemanticsLabel(english ? 'Password' : 'Contraseña'),
          'abc',
        );
        await tap(tester, find.text(create));
        for (final message in messages) {
          expect(find.text(message), findsOneWidget, reason: message);
        }

        await tester.enterText(
          find.bySemanticsLabel(english ? 'First name' : 'Nombre'),
          'a' * 61,
        );
        await tester.pumpAndSettle();
        expect(
          find.text(english ? 'Maximum 60 characters' : 'Máximo 60 caracteres'),
          findsOneWidget,
        );
      }
      semantics.dispose();
    },
  );
}
