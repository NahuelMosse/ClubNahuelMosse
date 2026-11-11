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

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  final themes = {'dark': darkTheme, 'light': lightTheme};

  Future<Session> sessionWith((int, String) change) async {
    final session = Session(
      repository: SessionRepository(
        credentials: FakeCredentials(),
        api: apiRoutes({
          'GET /me': (200, profileJson()),
          'PUT /me/password': change,
        }),
      ),
    );
    await session.signIn('nahuel@correo.com', 'ClubNahuel1');
    return session;
  }

  Future<void> typeInto(
    WidgetTester tester, {
    String current = 'ClubNahuel1',
    String newPassword = 'ClubNahuel2',
    String? repeated,
  }) async {
    await tester.enterText(find.bySemanticsLabel('Contraseña actual'), current);
    await tester.enterText(
      find.bySemanticsLabel('Contraseña nueva'),
      newPassword,
    );
    await tester.enterText(
      find.bySemanticsLabel('Repetir contraseña'),
      repeated ?? newPassword,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  }

  Future<void> capture(String file) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile(file));

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: theme) in themes.entries) {
      Future<void> mountWith(WidgetTester tester, (int, String) change) async {
        final session = await sessionWith(change);
        await mountScreen(
          tester,
          ChangePasswordScreen(session: session),
          theme: theme,
          size: size,
        );
      }

      testWidgets('empty password $width $mode', (tester) async {
        await mountWith(tester, (204, ''));
        await capture('users/password_empty_${width}_$mode.png');
      });

      testWidgets('password rules $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountWith(tester, (204, ''));
        await tester.enterText(
          find.bySemanticsLabel('Contraseña actual'),
          'ClubNahuel1',
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña nueva'),
          'ClubNahuel',
        );
        await tester.pump();
        await capture('users/password_rules_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('passwords do not match $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountWith(tester, (204, ''));
        await typeInto(tester, repeated: 'ClubNahuel3');
        await capture('users/passwords_do_not_match_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('wrong current password $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountWith(tester, (
          422,
          '{"errors": {"current_password": "La contraseña actual no coincide"}}',
        ));
        await typeInto(tester);
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await capture('users/current_password_wrong_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('password updated $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountWith(tester, (204, ''));
        await typeInto(tester);
        await tester.tap(find.text('GUARDAR CONTRASEÑA'));
        await tester.pumpAndSettle();
        await capture('users/password_updated_${width}_$mode.png');
        semantics.dispose();
      });

      for (final (name, open) in [
        (
          'error_connection',
          (BuildContext c) => showNetworkError(c, const NoConnection()),
        ),
        (
          'error_server',
          (BuildContext c) => showNetworkError(c, const ServerError(500)),
        ),
        ('session_expired', showSessionExpired),
      ]) {
        testWidgets('overlay $name $width $mode', (tester) async {
          await mountScreen(
            tester,
            Builder(
              builder: (c) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => open(c),
                    child: const Text('abrir'),
                  ),
                ),
              ),
            ),
            theme: theme,
            size: size,
          );
          await tester.tap(find.text('abrir'));
          await tester.pumpAndSettle();
          await capture('common/${name}_${width}_$mode.png');
        });
      }
    }
  }
}
