import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder card(String name) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(name)},'));

  Future<void> goTo(WidgetTester tester, String name) async {
    await waitUntil(tester, card(name));
    await tester.ensureVisible(card(name));
    await tester.pumpAndSettle();
    await tester.tap(card(name));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'offline, an operation shows the connection error with retry and what was loaded stays in view @TP-07-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await createSpace(name);
      final api = await ProxyApi.open();
      await signInAsUser(
        tester,
        email: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await tapText(tester, 'SEDES');
      await waitUntil(tester, card(name));

      api.state = ApiState.offline;
      await goTo(tester, name);

      // Verifies: the shared notice with its two exits. If it fails, the person is left
      // facing an empty screen without knowing what happened or how to go on.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(
        find.text(
          'No pudimos conectarnos. Revisá tu conexión a internet y volvé a intentar.',
        ),
        findsOneWidget,
      );
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);

      // Verifies: on going back, the listing that was already loaded is still there.
      await tapText(tester, 'Volver');
      await waitUntil(tester, card(name));
      semantics.dispose();
    },
  );

  testWidgets(
    'when the connection returns, retrying completes the operation @TP-07-H01-02 @assumption:TP-07-SUP-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final court = await createSpace(name);
      final api = await ProxyApi.open();
      await signInAsUser(
        tester,
        email: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );
      await tapText(tester, 'SEDES');
      await waitUntil(tester, card(name));
      api.state = ApiState.offline;
      await goTo(tester, name);
      await waitUntil(tester, find.text('Error de conexión'));

      api.state = ApiState.normal;

      // Verifies: with the network back the operation does not complete by itself; it
      // waits for the person's retry.
      expect(find.text(court), findsNothing);
      await tapText(tester, 'REINTENTAR');

      // Verifies: retrying completes what had been left half done.
      await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(court), findsOneWidget);
      expect(find.text('Error de conexión'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'with the server down, the server error is shown and no half-loaded data @TP-07-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final api = await ProxyApi.open();
      await signInAsUser(
        tester,
        email: 'socio.${unique()}@correo.com',
        apiUrl: api.url,
      );

      api.state = ApiState.failing;
      await tapText(tester, 'SEDES');

      // Verifies: the server notice with its only exit and nothing of the listing.
      await waitUntil(tester, find.text('Error del servidor'));
      expect(
        find.text(
          'No pudimos procesar la operación en este momento. Intentá más tarde.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'ACEPTAR');
      expect(card(name), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('a wrong login shows the generic message @TP-07-H03-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    await openApp(tester);

    await typeInto(tester, 'Correo', email);
    await typeInto(tester, 'Contraseña', 'OtraClave9');
    await tapText(tester, 'INICIAR SESIÓN');

    // Verifies: the message does not say which piece of data is wrong and the person stays on the login.
    await waitUntil(
      tester,
      find.text(
        'No se pudo iniciar sesión. Revisá tus datos e intentá de nuevo.',
      ),
    );
    expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'registering with an already used email shows that the user is already registered @TP-07-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = 'repetido.${unique()}@correo.com';
      await createAccount(email: email, password: 'ClubNahuel1');
      await openApp(tester);
      await tapText(tester, 'COMENZAR');
      await typeInto(tester, 'Nombre', 'Nahuel Agustín');
      await typeInto(tester, 'Apellido', 'Mosse');
      await typeInto(tester, 'DNI', dniOf(unique()));
      await typeInto(tester, 'Fecha de nacimiento', '14032000');
      await typeInto(tester, 'Correo electrónico', email);
      await typeInto(tester, 'Contraseña', 'ClubNahuel1');

      await tapText(tester, 'CREAR CUENTA');

      // Verifies: the prototype's notice and the person stays on the form.
      await waitUntil(
        tester,
        find.text(
          'El usuario ya está registrado. Modificá el correo o el DNI.',
        ),
      );
      expect(find.text('¡Cuenta creada!'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'with an expired session, a screen with data leads to the notice and to the sign-in @TP-07-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);
      await changeFromAnotherDevice(email, 'ClubNahuel1', 'ClubNahuel3');

      await tapText(tester, 'SEDES');

      // Verifies: it says the session expired, with no data, and leads to the sign-in.
      await waitUntil(tester, find.text('Tu sesión expiró'));
      expect(card(name), findsNothing);
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'a user without the administrator role who enters the panel sees «Acceso denegado» and reaches «Mis reservas» @TP-07-H06-01 @assumption:TP-07-SUP-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      // The direct route is the deliberate vector: the app does not offer the panel to a user,
      // and the copied link or the reopened session is the way to get there.
      await tester.binding.handlePushRoute('/admin');
      await tester.pumpAndSettle();

      // Verifies: the prototype's notice and nothing of the panel.
      await waitUntil(tester, find.text('Acceso denegado'));
      expect(
        find.text(
          'Tu cuenta no tiene permisos de administrador. Te llevamos a Mis reservas.',
        ),
        findsOneWidget,
      );
      expect(find.text('PANEL ADMIN'), findsNothing);

      // Verifies: the only exit leads to «Mis reservas».
      await tapText(tester, 'IR A MIS RESERVAS');
      await waitUntil(tester, find.text('Mis reservas'));
      expect(find.text('Acceso denegado'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'if the court was deactivated while being viewed, it sees «Esto cambió mientras tanto» and the real state @TP-07-H07-01 @assumption:TP-07-SUP-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venue = 'Sede Haedo ${unique()}';
      await createVenue(venue, 'Av. Vergara 1850');
      final court1 = await createSpace(venue);
      final court2 = await createSpace(venue);
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await tapText(tester, 'SEDES');
      await goTo(tester, venue);
      // The venue has two courts: the first one's times are opened, which is court1.
      final book = find.text('VER HORARIOS / RESERVAR').first;
      await tester.ensureVisible(book);
      await tester.pumpAndSettle();
      await tester.tap(book);
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));

      await deactivateSpaceFromAnotherSession(court1);
      await tester.tap(find.bySemanticsLabel('Una hora más'));
      await tester.pumpAndSettle();

      // Verifies: the shared notice, and on accepting it the venue without the deactivated court.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text(court2));
      expect(find.text(court1), findsNothing);
      semantics.dispose();
    },
  );
}
