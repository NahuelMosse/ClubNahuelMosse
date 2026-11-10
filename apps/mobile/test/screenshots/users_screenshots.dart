import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/features/session/data/session_repository.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:clubnahuelmosse/features/users/presentation/change_password_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';

/// No afirma nada: produce la tira del paso 9 para mirarla contra el prototipo.
void main() {
  setUpAll(loadFonts);

  const telefonos = {'360': Size(360, 800), '430': Size(430, 932)};
  final temas = {'dark': darkTheme, 'light': lightTheme};

  Future<Session> sesionCon((int, String) cambio) async {
    final sesion = Session(
      repository: SessionRepository(
        credentials: FakeCredentials(),
        api: apiRoutes({
          'GET /me': (200, profileJson()),
          'PUT /me/password': cambio,
        }),
      ),
    );
    await sesion.signIn('nahuel@correo.com', 'ClubNahuel1');
    return sesion;
  }

  Future<void> escribir(
    WidgetTester tester, {
    String actual = 'ClubNahuel1',
    String nueva = 'ClubNahuel2',
    String? repetida,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), actual);
    await tester.enterText(find.bySemanticsLabel('Contraseña nueva'), nueva);
    await tester.enterText(
      find.bySemanticsLabel('Repetir contraseña'),
      repetida ?? nueva,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> capturar(String archivo) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(archivo));

  for (final MapEntry(key: ancho, value: tamano) in telefonos.entries) {
    for (final MapEntry(key: modo, value: tema) in temas.entries) {
      Future<void> montarCon(WidgetTester tester, (int, String) cambio) async {
        final sesion = await sesionCon(cambio);
        await mountScreen(
          tester,
          ChangePasswordScreen(session: sesion),
          tema: tema,
          tamano: tamano,
        );
      }

      testWidgets('contraseña vacía $ancho $modo', (tester) async {
        await montarCon(tester, (204, ''));
        await capturar('users/password_empty_${ancho}_$modo.png');
      });

      testWidgets('contraseña reglas $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (204, ''));
        await tester.enterText(
          find.bySemanticsLabel('Contraseña actual'),
          'ClubNahuel1',
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña nueva'),
          'ClubNahuel',
        );
        await tester.pump();
        await capturar('users/password_rules_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('contraseña no coinciden $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (204, ''));
        await escribir(tester, repetida: 'ClubNahuel3');
        await capturar('users/passwords_do_not_match_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('contraseña actual equivocada $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (
          422,
          '{"errors": {"current_password": "La contraseña actual no coincide"}}',
        ));
        await escribir(tester);
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await capturar('users/current_password_wrong_${ancho}_$modo.png');
        semantica.dispose();
      });

      testWidgets('contraseña actualizada $ancho $modo', (tester) async {
        final semantica = tester.ensureSemantics();
        await montarCon(tester, (204, ''));
        await escribir(tester);
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await capturar('users/password_updated_${ancho}_$modo.png');
        semantica.dispose();
      });

      for (final (nombre, abrir) in [
        (
          'error_connection',
          (BuildContext c) => showNetworkError(c, const SinConexion()),
        ),
        (
          'error_server',
          (BuildContext c) => showNetworkError(c, const ErrorDelServidor(500)),
        ),
        ('session_expired', showSessionExpired),
      ]) {
        testWidgets('overlay $nombre $ancho $modo', (tester) async {
          await mountScreen(
            tester,
            Builder(
              builder: (c) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => abrir(c),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
            tema: tema,
            tamano: tamano,
          );
          await tester.tap(find.text('abrir'));
          await tester.pumpAndSettle();
          await capturar('common/${nombre}_${ancho}_$modo.png');
        });
      }
    }
  }
}
