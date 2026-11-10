import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tomorrow = todayAtClub().add(const Duration(days: 1));

  Future<void> tapLabel(WidgetTester tester, String label) async {
    final control = find.bySemanticsLabel(label);
    await waitUntil(tester, control);
    await tester.ensureVisible(control);
    await tester.pumpAndSettle();
    await tester.tap(control);
    await tester.pumpAndSettle();
  }

  /// From the panel to the edit screen of the venue [name].
  Future<void> openEdit(WidgetTester tester, String name) async {
    await tapText(tester, 'SEDES');
    await waitUntil(tester, find.text('AGREGAR SEDE'));
    await tapLabel(tester, 'Editar sede $name');
    await waitUntil(tester, find.text('Editar sede'));
  }

  /// From the edit screen, up to the confirmation dialog.
  Future<void> requestDeactivation(WidgetTester tester) async {
    await tapText(tester, 'DAR DE BAJA LA SEDE');
    await waitUntil(tester, find.text('¿Dar de baja la sede?'));
  }

  testWidgets(
    'deactivates a venue with no future bookings, sees the success and the venue stops showing for the users @CU-19-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await createSpace(name);
      await signInAsAdmin(tester);
      await openEdit(tester, name);
      await requestDeactivation(tester);

      await tapText(tester, 'DAR DE BAJA');

      // Verifies: the notice, the listing without the venue and the users no longer see it.
      await waitUntil(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );
      expect(find.text('AGREGAR SEDE'), findsOneWidget);
      expect(find.text(name), findsNothing);
      expect(await venueAUserSees(name), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'after the deactivation, the spaces of that venue cannot be booked @CU-19-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final court = await createSpace(name);
      final other = await createSpace(name);
      await signInAsAdmin(tester);
      await openEdit(tester, name);
      await requestDeactivation(tester);

      await tapText(tester, 'DAR DE BAJA');
      await waitUntil(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );

      // Verifies: none of its courts is offered for booking.
      final spaces = await spacesAUserSees();
      expect(spaces, isNot(contains(court)));
      expect(spaces, isNot(contains(other)));
      semantics.dispose();
    },
  );

  testWidgets(
    'starts the deactivation from the venue card in the panel listing @CU-19-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await tapText(tester, 'SEDES');
      await waitUntil(tester, find.text('AGREGAR SEDE'));

      await tapLabel(tester, 'Dar de baja $name');
      await waitUntil(tester, find.text('¿Dar de baja la sede?'));
      expect(find.textContaining('$name · Av. Vergara 1850'), findsOneWidget);
      await tapText(tester, 'DAR DE BAJA');

      // Verifies: the notice and the listing without the venue.
      await waitUntil(
        tester,
        find.text('La sede fue dada de baja correctamente'),
      );
      expect(find.text(name), findsNothing);
      expect(await venueAUserSees(name), isNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'cancels in the dialog and the venue stays the same @CU-19-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await openEdit(tester, name);
      await requestDeactivation(tester);

      await tapText(tester, 'CANCELAR');

      // Verifies: stays on the edit screen and the venue stays active.
      expect(find.text('¿Dar de baja la sede?'), findsNothing);
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await venueAUserSees(name), isNotNull);
      semantics.dispose();
    },
  );

  testWidgets(
    'the venue was already deactivated in another session and is told it is not available @CU-19-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await openEdit(tester, name);
      await requestDeactivation(tester);

      await deactivateVenueFromAnotherSession(name);
      await tapText(tester, 'DAR DE BAJA');

      // Verifies: the notice and the refreshed listing, without the venue.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('AGREGAR SEDE'));
      expect(find.text(name), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the venue has future bookings and the deactivation is not allowed @CU-19-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final court = await createSpace(name);
      await occupy(court, tomorrow, 21);
      await signInAsAdmin(tester);
      await openEdit(tester, name);
      await requestDeactivation(tester);

      await tapText(tester, 'DAR DE BAJA');

      // Verifies: the notice, and the venue and its court stay available.
      await waitUntil(tester, find.text('No se puede dar de baja la sede'));
      expect(
        find.text(
          'La sede posee reservas futuras asociadas a sus espacios deportivos. '
          'Gestionalas primero.',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await venueAUserSees(name), isNotNull);
      expect(await spacesAUserSees(), contains(court));
      semantics.dispose();
    },
  );

  testWidgets(
    'the deactivation fails, sees the error and stays on the edit screen with the venue intact @CU-19-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await openEdit(tester, name);
      await requestDeactivation(tester);

      api.state = ApiState.failing;
      await tapText(tester, 'DAR DE BAJA');

      // Verifies: the error, stays on the edit screen and the venue is active.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Editar sede'), findsOneWidget);
      expect(await venueAUserSees(name), isNotNull);
      semantics.dispose();
    },
  );
}
