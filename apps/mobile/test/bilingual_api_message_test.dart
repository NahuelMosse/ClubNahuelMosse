import 'dart:ui';

import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];
const _spanish = [Locale('es', 'AR')];

void main() {
  setUpAll(cargarFuentes);

  // One test per device: the semantics tree of a screen mounted over another one is not
  // rebuilt for the new language, so each language mounts on a clean tester.
  for (final (name, device, signIn, email, password) in [
    ('English', _english, 'SIGN IN', 'Email', 'Password'),
    ('Spanish', _spanish, 'INICIAR SESIÓN', 'Correo', 'Contraseña'),
  ]) {
    testWidgets(
      'a message the API sends is shown as it arrives, in both languages @ENG-19-ASM-04 ($name)',
      (tester) async {
        const message = 'Demasiados intentos. Esperá un minuto.';
        final semantics = tester.ensureSemantics();
        tester.platformDispatcher.localesTestValue = device;
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        final session = Session(
          repository: SessionRepository(
            credentials: CredencialesFalsas(),
            api: apiFalsa(codigo: 429, cuerpo: '{"mensaje": "$message"}'),
          ),
        );
        await montar(
          tester,
          LoginScreen(session: session, pending: PendingBooking()),
          tema: darkTheme,
        );
        await tester.enterText(find.bySemanticsLabel(email), 'a@b.com');
        await tester.enterText(find.bySemanticsLabel(password), 'Clave1234');
        await tester.tap(find.text(signIn));
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        semantics.dispose();
      },
    );
  }
}
