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

import 'soporte/montar.dart';
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
  setUpAll(cargarFuentes);

  Widget login({bool rechaza = false}) => LoginScreen(
    pending: PendingBooking(),
    session: Session(
      repository: SessionRepository(
        credentials: CredencialesFalsas(
          alIngresar: rechaza
              ? (_, _) async => throw const InvalidCredentials()
              : null,
        ),
        api: apiFalsa(codigo: 200, cuerpo: perfilJson()),
      ),
    ),
  );

  Future<void> cumpleLasGuias(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final temas = {'oscuro': darkTheme, 'claro': lightTheme};
  final pantallas = <String, Widget Function()>{
    'el login': login,
    'el Home': () => inicioFalso(SesionFalsa(perfilUsuario)),
    'el panel de administración': () {
      final sesion = SesionFalsa(perfilAdmin);
      final api = apiRutas({
        'GET /bookings/all': (
          200,
          '{"bookings": [], "total": 0, "page": 1, "per_page": 20,'
              ' "counters": {"all": 0, "active": 0, "completed": 0,'
              ' "voided": 0}}',
        ),
      });
      return AdminPanelScreen(
        history: BookingHistory(api: api, sesion: sesion),
        venues: Venues(
          repository: VenuesRepository(api: api, session: sesion),
        ),
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: sesion),
        ),
        session: sesion,
        pending: PendingPanelFilters(),
      );
    },
    'recuperar contraseña': () => ForgotPasswordScreen(
      recovery: PasswordRecovery(apiFalsa(codigo: 202, cuerpo: '')),
    ),
    'Mi perfil': () => MyProfileScreen(
      session: SesionFalsa(perfilUsuario),
      appearance: Appearance.inMemory(),
    ),
    'la contraseña nueva': () => NewPasswordScreen(
      recovery: PasswordRecovery(apiFalsa(codigo: 204, cuerpo: '')),
      session: SesionFalsa(null),
      code: 'abc',
    ),
    'el enlace inválido': () => NewPasswordScreen(
      recovery: PasswordRecovery(apiFalsa(codigo: 410, cuerpo: '')),
      session: SesionFalsa(null),
      code: 'abc',
    ),
    'cambiar contraseña': () =>
        ChangePasswordScreen(session: SesionFalsa(perfilUsuario)),
  };

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    for (final MapEntry(key: nombre, value: pantalla) in pantallas.entries) {
      testWidgets('$nombre cumple las guías de accesibilidad en modo $modo', (
        tester,
      ) async {
        final semantica = tester.ensureSemantics();
        await montar(tester, pantalla(), tema: tema);
        await cumpleLasGuias(tester);
        semantica.dispose();
      });
    }

    testWidgets('el login con errores y aviso cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(tester, login(rechaza: true), tema: tema);
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      await tester.enterText(find.bySemanticsLabel('Correo'), 'n@correo.com');
      await tester.enterText(find.bySemanticsLabel('Contraseña'), 'Mala1234');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pumpAndSettle();
      expect(find.text(invalidCredentialsMessage), findsOneWidget);
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    testWidgets('el perfil en edición cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        MyProfileScreen(
          session: SesionFalsa(perfilUsuario),
          appearance: Appearance.inMemory(),
        ),
        tema: tema,
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  for (final MapEntry(key: modo, value: tema) in temas.entries) {
    testWidgets('la confirmación de la baja cumple las guías en modo $modo', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        MyProfileScreen(
          session: SesionFalsa(perfilUsuario),
          appearance: Appearance.inMemory(),
        ),
        tema: tema,
      );
      await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ELIMINAR CUENTA'));
      await tester.pumpAndSettle();
      await cumpleLasGuias(tester);
      semantica.dispose();
    });
  }

  testWidgets('los campos del login anuncian su nombre', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, login(), tema: darkTheme);
    expect(find.bySemanticsLabel('Correo'), findsOneWidget);
    expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
    expect(find.bySemanticsLabel('Club Nahuel Mosse'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('con el texto al 200 % nada se desborda', (tester) async {
    for (final pantalla in pantallas.values) {
      await montar(
        tester,
        pantalla(),
        tema: darkTheme,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
