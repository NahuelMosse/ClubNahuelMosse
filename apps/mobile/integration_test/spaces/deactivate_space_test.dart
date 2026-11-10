import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final control = find.bySemanticsLabel(label);
    await waitUntil(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// A venue with two Fútbol 5: returns the venue and the two courts.
  Future<(String, String, String)> venueWithTwo() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    return (venue, await createSpace(venue), await createSpace(venue));
  }

  /// From the panel to the deactivation confirmation of [name].
  Future<void> requestDeactivation(WidgetTester tester, String name) async {
    await tapText(tester, 'ESPACIOS');
    await waitUntil(tester, find.text('ALTA ESPACIO'));
    await tapLabel(tester, 'Baja $name');
    await waitUntil(tester, find.text('¿Dar de baja el espacio?'));
  }

  testWidgets(
    'deactivates a space and it stops appearing in the panel and in the venue for users @CU-23-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, _) = await venueWithTwo();
      await signInAsAdmin(tester);
      await requestDeactivation(tester, court);
      expect(find.text('$court. La acción es permanente.'), findsOneWidget);

      await tapText(tester, 'CONFIRMAR BAJA');

      // Verifies: the notice, the panel without the space and users no longer see it.
      await waitUntil(
        tester,
        find.text('El espacio fue dado de baja correctamente'),
      );
      expect(find.text('ALTA ESPACIO'), findsOneWidget);
      expect(find.text(court), findsNothing);
      expect(await spaceAUserSees(court), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'after the deactivation, the venue shows one space fewer @CU-23-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court, _) = await venueWithTwo();
      expect((await venueAUserSees(venue))?['space_count'], 2);
      await signInAsAdmin(tester);
      await requestDeactivation(tester, court);

      await tapText(tester, 'CONFIRMAR BAJA');
      await waitUntil(
        tester,
        find.text('El espacio fue dado de baja correctamente'),
      );

      // Verifies: the venue is left with one court.
      expect((await venueAUserSees(venue))?['space_count'], 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'after the deactivation, the space cannot be booked @CU-23-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, other) = await venueWithTwo();
      await signInAsAdmin(tester);
      await requestDeactivation(tester, court);

      await tapText(tester, 'CONFIRMAR BAJA');
      await waitUntil(
        tester,
        find.text('El espacio fue dado de baja correctamente'),
      );

      // Verifies: it is not offered for booking; the venue's other court is.
      final spaces = await spacesAUserSees();
      expect(spaces, isNot(contains(court)));
      expect(spaces, contains(other));
      semantics.dispose();
    },
  );

  testWidgets(
    'cancels on the confirmation and the space stays the same @CU-23-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, _) = await venueWithTwo();
      await signInAsAdmin(tester);
      await requestDeactivation(tester, court);

      await tapText(tester, 'CANCELAR');

      // Verifies: it stays on the panel and the space is still active.
      expect(find.text('¿Dar de baja el espacio?'), findsNothing);
      expect(find.text(court), findsOneWidget);
      expect(await spaceAUserSees(court), isNotNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline or with the server down on confirming, the space is not deactivated @CU-23-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, _) = await venueWithTwo();
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await requestDeactivation(tester, court);

      api.state = ApiState.offline;
      await tapText(tester, 'CONFIRMAR BAJA');

      // Verifies: offline, the notice and the space stays.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text(court), findsOneWidget);
      expect(await spaceAUserSees(court), isNotNull);

      api.state = ApiState.failing;
      await requestDeactivation(tester, court);
      await tapText(tester, 'CONFIRMAR BAJA');

      // Verifies: with the server down, the same.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text(court), findsOneWidget);
      expect(await spaceAUserSees(court), isNotNull);
      semantics.dispose();
    },
  );
}
