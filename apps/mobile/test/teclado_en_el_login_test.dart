import 'package:clubnahuelmosse/common/pending_booking.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/domain/session_exceptions.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_background.dart';
import 'package:clubnahuelmosse/features/session/presentation/login_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _pantalla = Size(393, 852);
const _alturaTeclado = 300.0;
const _arribaDelTeclado = 852.0 - _alturaTeclado;

void main() {
  setUpAll(cargarFuentes);

  Future<void> montarLogin(
    WidgetTester tester, {
    CredencialesFalsas? credenciales,
  }) async {
    tester.view.physicalSize = _pantalla * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
        home: LoginScreen(
          session: Session(
            repository: SessionRepository(
              credentials: credenciales ?? CredencialesFalsas(),
              api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
            ),
          ),
          pending: PendingBooking(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> abrirTeclado(WidgetTester tester) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: _alturaTeclado * 3);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'con el teclado abierto la foto del inicio de sesión ocupa la misma área @SES-01-S1 @assumption:SES-01-ASM-01',
    (tester) async {
      await montarLogin(tester);
      final cerrado = tester.getRect(find.byType(LoginBackground));

      await abrirTeclado(tester);

      expect(tester.getRect(find.byType(LoginBackground)), cerrado);
    },
  );

  testWidgets(
    'con el teclado abierto el botón de ingresar se alcanza desplazando @SES-01-S2',
    (tester) async {
      await montarLogin(tester);
      await abrirTeclado(tester);

      await tester.ensureVisible(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('INICIAR SESIÓN')).bottom,
        lessThanOrEqualTo(_arribaDelTeclado),
      );
    },
  );

  testWidgets(
    'con el teclado abierto el aviso de credenciales inválidas queda por encima del teclado @assumption:SES-01-ASM-02',
    (tester) async {
      await montarLogin(
        tester,
        credenciales: CredencialesFalsas(
          alIngresar: (_, _) async => throw const InvalidCredentials(),
        ),
      );
      await tester.enterText(find.bySemanticsLabel('Correo'), 'a@correo.com');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
      await abrirTeclado(tester);

      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();

      expect(find.text(invalidCredentialsMessage), findsOneWidget);
      expect(
        tester.getRect(find.byTooltip('Cerrar aviso')).bottom,
        lessThanOrEqualTo(_arribaDelTeclado),
      );
    },
  );
}
