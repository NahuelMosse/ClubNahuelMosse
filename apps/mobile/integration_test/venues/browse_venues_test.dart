import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openVenues(WidgetTester tester) async {
    await tapText(tester, 'SEDES');
    await waitUntil(tester, find.text('Sedes'));
  }

  /// The card of the venue [name] in the listing, by its accessible label.
  Finder card(String name) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(name)},'));

  Future<void> enter(WidgetTester tester, String name) async {
    await waitUntil(tester, card(name));
    await tester.ensureVisible(card(name));
    await tester.pumpAndSettle();
    await tester.tap(card(name));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sees the venue listing with name, address, schedule, number of courts and sports @CU-16-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Ituzaingó ${unique()}';
      await createVenue(name, 'Av. Ratti 1400');
      await createSpace(name);
      await createSpace(name, sport: 'Tenis', kind: 'PDL');
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await openVenues(tester);

      // Verifies: the card shows the venue with its schedule, its courts and its sports.
      await waitUntil(
        tester,
        find.bySemanticsLabel(
          '$name, Av. Ratti 1400, Lunes a domingo de 08:00 a 23:00, '
          '2 canchas: Fútbol, Tenis',
        ),
      );
      expect(find.text(name.toUpperCase()), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'enters a venue and sees all its courts with the total counter and the data of each @CU-16-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Ituzaingó ${unique()}';
      await createVenue(name, 'Av. Ratti 1400');
      final football = await createSpace(name);
      final tennis = await createSpace(name, sport: 'Tenis', kind: 'PDL');
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await openVenues(tester);

      await enter(tester, name);

      // Verifies: the venue shows its cover with the counter and each court with its data.
      await waitUntil(tester, find.text('2 CANCHAS · TODOS LOS DEPORTES'));
      expect(find.text(name.toUpperCase()), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Fútbol 5, $football, Techada, Iluminada, 43.000 pesos por hora',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Tenis, $tennis, Techada, Iluminada, 43.000 pesos por hora',
        ),
        findsOneWidget,
      );
      expect(find.text('VER HORARIOS / RESERVAR'), findsNWidgets(2));
      semantics.dispose();
    },
  );

  testWidgets(
    'a venue just loaded with its court shows in the listing with that court @CU-16-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Ituzaingó ${unique()}';
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await openVenues(tester);
      expect(card(name), findsNothing);

      // The administrator loads it while the user already has the app open.
      await createVenue(name, 'Av. Ratti 1400');
      final court = await createSpace(name);
      await tapText(tester, 'INICIO');
      await openVenues(tester);

      // Verifies: it shows with its court, and inside is that court.
      await waitUntil(
        tester,
        find.bySemanticsLabel(
          '$name, Av. Ratti 1400, Lunes a domingo de 08:00 a 23:00, '
          '1 cancha: Fútbol',
        ),
      );
      await enter(tester, name);
      await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(court), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('from a court goes on to look up its times @CU-16-H01-04', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final name = 'Sede Ituzaingó ${unique()}';
    await createVenue(name, 'Av. Ratti 1400');
    await createSpace(name);
    await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
    await openVenues(tester);
    await enter(tester, name);
    await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));

    await tapText(tester, 'VER HORARIOS / RESERVAR');

    // Verifies: reaches the times of that venue with that court picked.
    await waitUntil(tester, find.text('SELECCIONÁ CANCHA'));
    expect(find.text(name.toUpperCase()), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Cancha 1, Techada'))
          .flagsCollection
          .isSelected,
      isTrue,
    );
    semantics.dispose();
  });

  testWidgets(
    'enters a venue with no courts and sees the notice with the counter at zero @CU-16-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await openVenues(tester);

      await enter(tester, name);

      // Verifies: the cover with the counter at zero and the notice in place of the listing.
      await waitUntil(tester, find.text('0 CANCHAS'));
      expect(find.text(name.toUpperCase()), findsOneWidget);
      expect(find.text('Todavía no hay canchas'), findsOneWidget);
      expect(
        find.text('Esta sede no tiene canchas disponibles por el momento.'),
        findsOneWidget,
      );
      expect(find.text('VER HORARIOS / RESERVAR'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('goes back to «Todas las sedes» from a venue @CU-16-H03-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final name = 'Sede Haedo ${unique()}';
    await createVenue(name, 'Av. Vergara 1850');
    await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
    await openVenues(tester);
    await enter(tester, name);
    await waitUntil(tester, find.text('0 CANCHAS'));

    await tapText(tester, 'Todas las sedes');

    // Verifies: back to the listing, with the venue it was looking at.
    await waitUntil(tester, find.text('Sedes'));
    expect(find.text('0 CANCHAS'), findsNothing);
    expect(card(name), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'with no connection, sees the error with a retry option and stays on the same screen @CU-16-H04-01',
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
      await openVenues(tester);
      await waitUntil(tester, card(name));

      api.state = ApiState.offline;
      await enter(tester, name);

      // Verifies: warns of no connection, and on retrying with the network back shows the venue.
      await waitUntil(tester, find.text('Error de conexión'));
      api.state = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.text('1 CANCHA · TODOS LOS DEPORTES'));
      expect(find.text(court), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('the server fails and no partial data is shown @CU-16-H05-01', (
    tester,
  ) async {
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

    // Verifies: warns of the server and no venue is left in view.
    await waitUntil(tester, find.text('Error del servidor'));
    await tapText(tester, 'ACEPTAR');
    expect(card(name), findsNothing);
    expect(find.text('Ver canchas'), findsNothing);
    semantics.dispose();
  });
}
