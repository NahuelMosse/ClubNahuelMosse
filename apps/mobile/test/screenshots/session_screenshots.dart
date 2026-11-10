import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'package:clubnahuelmosse/features/venues/data/venues_repository.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_panel_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../support/mount.dart';
import '../support/fixed_clock.dart';
import 'package:clubnahuelmosse/features/session/data/password_recovery.dart';
import 'package:clubnahuelmosse/features/session/presentation/forgot_password_screen.dart';
import 'package:clubnahuelmosse/features/session/presentation/new_password_screen.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';
import 'package:clubnahuelmosse/features/users/presentation/my_profile_screen.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venues.dart';

/// Asserts nothing: produces the step-9 strip to compare against the prototype.
void main() {
  setUpAll(loadFonts);

  const phones = {'360': Size(360, 800), '430': Size(430, 932)};
  final themes = {'dark': darkTheme, 'light': lightTheme};

  Future<void> capture(WidgetTester tester, String file) async {
    // The background photo is decoded outside the test's fake clock.
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        final image = element.widget;
        if (image is Image) await precacheImage(image.image, element);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile(file));
  }

  for (final MapEntry(key: width, value: size) in phones.entries) {
    for (final MapEntry(key: mode, value: theme) in themes.entries) {
      testWidgets('empty login $width $mode', (tester) async {
        await mountScreen(
          tester,
          loginRejectingCredentials(),
          theme: theme,
          size: size,
        );
        await capture(tester, 'session/login_empty_${width}_$mode.png');
      });

      testWidgets('login incomplete fields $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          loginRejectingCredentials(),
          theme: theme,
          size: size,
        );
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await capture(tester, 'session/login_incomplete_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('login invalid credentials $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          loginRejectingCredentials(),
          theme: theme,
          size: size,
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo'),
          'nmosse@unimoron.edu.ar',
        );
        await tester.enterText(
          find.bySemanticsLabel('Contraseña'),
          'Clave1234',
        );
        await tester.tap(find.text('INICIAR SESIÓN'));
        await tester.pumpAndSettle();
        await capture(tester, 'session/login_invalid_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('home $width $mode', (tester) async {
        await mountScreen(
          tester,
          fakeHome(FakeSession(userProfile)),
          theme: theme,
          size: size,
        );
        await capture(tester, 'session/home_${width}_$mode.png');
      });

      testWidgets('account card $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          fakeHome(FakeSession(userProfile)),
          theme: theme,
          size: size,
        );
        await tester.tap(find.bySemanticsLabel('Tu cuenta'));
        await tester.pumpAndSettle();
        await capture(tester, 'session/account_card_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('my profile $width $mode', (tester) async {
        await mountScreen(
          tester,
          MyProfileScreen(
            session: FakeSession(userProfile),
            appearance: Appearance.inMemory(dark: mode == 'dark'),
          ),
          theme: theme,
          size: size,
        );
        await capture(tester, 'session/my_profile_${width}_$mode.png');
      });

      testWidgets('recover invalid email $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          ForgotPasswordScreen(
            recovery: PasswordRecovery(fakeApi(status: 202, body: '')),
          ),
          theme: theme,
          size: size,
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo electrónico'),
          'nmosse@unimoron',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await capture(tester, 'session/recover_invalid_${width}_$mode.png');
        semantics.dispose();
      });

      testWidgets('recover sent $width $mode', (tester) async {
        final semantics = tester.ensureSemantics();
        await mountScreen(
          tester,
          ForgotPasswordScreen(
            recovery: PasswordRecovery(fakeApi(status: 202, body: '')),
          ),
          theme: theme,
          size: size,
        );
        await tester.enterText(
          find.bySemanticsLabel('Correo electrónico'),
          'nmosse@unimoron.edu.ar',
        );
        await tester.pump();
        await tester.tap(find.text('ENVIAR ENLACE'));
        await tester.pumpAndSettle();
        await capture(tester, 'session/recover_sent_${width}_$mode.png');
        semantics.dispose();
      });

      for (final (name, status) in [('new', 204), ('link_invalid', 410)]) {
        testWidgets('recover $name $width $mode', (tester) async {
          await mountScreen(
            tester,
            NewPasswordScreen(
              recovery: PasswordRecovery(fakeApi(status: status, body: '')),
              session: FakeSession(null),
              code: 'abc',
            ),
            theme: theme,
            size: size,
          );
          await capture(tester, 'session/recover_${name}_${width}_$mode.png');
        });
      }

      for (final (name, invalid) in [('edit', false), ('edit_invalid', true)]) {
        testWidgets('my profile $name $width $mode', (tester) async {
          final semantics = tester.ensureSemantics();
          await mountScreen(
            tester,
            MyProfileScreen(
              session: FakeSession(userProfile),
              appearance: Appearance.inMemory(dark: mode == 'dark'),
            ),
            theme: theme,
            size: size,
          );
          await tester.tap(find.text('Editar'));
          await tester.pumpAndSettle();
          if (invalid) {
            await tester.enterText(find.bySemanticsLabel('DNI'), '42118');
            await tester.enterText(
              find.bySemanticsLabel('Fecha de nacimiento'),
              '32132000',
            );
            await tester.ensureVisible(find.text('GUARDAR'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('GUARDAR'));
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('DATOS PERSONALES'));
            await tester.pumpAndSettle();
          }
          await capture(
            tester,
            'session/my_profile_${name}_${width}_$mode.png',
          );
          semantics.dispose();
        });
      }

      testWidgets('my profile confirm deactivation $width $mode', (
        tester,
      ) async {
        await mountScreen(
          tester,
          MyProfileScreen(
            session: FakeSession(userProfile),
            appearance: Appearance.inMemory(dark: mode == 'dark'),
          ),
          theme: theme,
          size: size,
        );
        await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('ELIMINAR CUENTA'));
        await tester.pumpAndSettle();
        await capture(tester, 'session/confirm_deactivate_${width}_$mode.png');
      });

      testWidgets('admin panel $width $mode', (tester) async {
        final adminSession = FakeSession(adminProfile);
        final panelApi = apiRoutes({
          'GET /bookings/all': (
            200,
            '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
                ' "counters": {"all": 0, "active": 0, "completed": 0,'
                ' "voided": 0}}',
          ),
        });
        await mountScreen(
          tester,
          AdminPanelScreen(
            history: BookingHistory(api: panelApi, sesion: adminSession),
            venues: Venues(
              repository: VenuesRepository(
                api: panelApi,
                session: adminSession,
              ),
            ),
            spaces: Spaces(
              repository: SpacesRepository(
                api: panelApi,
                session: adminSession,
              ),
            ),
            session: adminSession,
            pending: PendingPanelFilters(),
          ),
          theme: theme,
          size: size,
        );
        await capture(tester, 'session/panel_admin_${width}_$mode.png');
      });

      testWidgets('recover password $width $mode', (tester) async {
        await mountScreen(
          tester,
          ForgotPasswordScreen(
            recovery: PasswordRecovery(fakeApi(status: 202, body: '')),
          ),
          theme: theme,
          size: size,
        );
        await capture(tester, 'session/recover_${width}_$mode.png');
      });
    }
  }
}
