import 'dart:ui' show SemanticsFlags;

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

  SemanticsFlags flags(WidgetTester tester, String label) =>
      tester.getSemantics(find.bySemanticsLabel(label)).flagsCollection;

  /// A venue with a covered, lit Fútbol 5 at $ 43.000 an hour.
  Future<String> oneSpace() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    return createSpace(venue);
  }

  /// From the panel to the edit screen of the space [name].
  Future<void> openEdit(WidgetTester tester, String name) async {
    await tapText(tester, 'ESPACIOS');
    await waitUntil(tester, find.text('ALTA ESPACIO'));
    await tapLabel(tester, 'Editar $name');
    await waitUntil(tester, find.text('Editar espacio deportivo'));
  }

  testWidgets(
    'changes the price of a space and the listing and the venue show the new one @CU-22-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      await signInAsAdmin(tester);
      await openEdit(tester, court);

      await typeInto(tester, 'Precio por hora', '45000');
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifies: the notice, the listing with the new price and users see it.
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      await waitUntil(
        tester,
        find.bySemanticsLabel(
          RegExp('45\\.000 por hora, .*${RegExp.escape(court)}\$'),
        ),
      );
      expect((await spaceAUserSees(court))?['price_per_hour'], 45000);
      semantics.dispose();
    },
  );

  testWidgets(
    'a booking made before the change keeps its price and a new one uses the new one @CU-22-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: 'ClubNahuel1');
      expect(await bookThroughApi(email, court, tomorrow, 20), 43000);
      await signInAsAdmin(tester);
      await openEdit(tester, court);

      await typeInto(tester, 'Precio por hora', '45000');
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );

      // Verifies: the earlier one stays at $ 43.000 and the new one comes out at $ 45.000.
      expect(await bookThroughApi(email, court, tomorrow, 21), 45000);
      expect(await bookingTotals(email), {'20:00': 43000, '21:00': 45000});
      semantics.dispose();
    },
  );

  testWidgets('venue, sport and kind cannot be edited @CU-22-H01-03', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final court = await oneSpace();
    await signInAsAdmin(tester);

    await openEdit(tester, court);

    // Verifies: the three disabled, with their values, and the name confirmed.
    expect(flags(tester, 'Sede').isEnabled, isFalse);
    expect(flags(tester, 'Deporte').isEnabled, isFalse);
    expect(flags(tester, 'Tipo').isEnabled, isFalse);
    expect(find.text('Fútbol 5'), findsWidgets);
    expect(find.text(court), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('cancels and the price does not change @CU-22-H02-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final court = await oneSpace();
    await signInAsAdmin(tester);
    await openEdit(tester, court);
    await typeInto(tester, 'Precio por hora', '45000');

    await tapText(tester, 'CANCELAR');

    // Verifies: it returns to the listing and the price is still the earlier one.
    await waitUntil(tester, find.text('ALTA ESPACIO'));
    expect((await spaceAUserSees(court))?['price_per_hour'], 43000);
    semantics.dispose();
  });

  testWidgets(
    'leaves the price empty, zero or with letters and cannot save @CU-22-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      await signInAsAdmin(tester);
      await openEdit(tester, court);

      // Verifies: empty, the required notice and unable to save.
      await typeInto(tester, 'Precio por hora', '');
      expect(find.text('Este campo es obligatorio'), findsOneWidget);
      expect(flags(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);

      // Verifies: zero, the range notice.
      await typeInto(tester, 'Precio por hora', '0');
      expect(
        find.text('Ingresá un precio entre \$ 1 y \$ 9.999.999'),
        findsOneWidget,
      );
      expect(flags(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);

      // Verifies: letters are not typed.
      await typeInto(tester, 'Precio por hora', 'abc');
      expect(find.text('abc'), findsNothing);
      expect(flags(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);
      expect((await spaceAUserSees(court))?['price_per_hour'], 43000);
      semantics.dispose();
    },
  );

  testWidgets(
    'without modifying anything, the save button stays disabled @CU-22-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      await signInAsAdmin(tester);

      await openEdit(tester, court);

      // Verifies: without changes it cannot save; with a change, it can.
      expect(flags(tester, 'GUARDAR ESPACIO').isEnabled, isFalse);
      await choose(tester, 'Condición', 'Al aire libre');
      expect(flags(tester, 'GUARDAR ESPACIO').isEnabled, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'the space was deactivated in another session and it is warned on saving @CU-22-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      await signInAsAdmin(tester);
      await openEdit(tester, court);
      await typeInto(tester, 'Precio por hora', '45000');

      await deactivateSpaceFromAnotherSession(court);
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifies: the notice and the listing without that space.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('ALTA ESPACIO'));
      expect(find.text(court), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline on saving, it sees the error and keeps the typed price @CU-22-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await openEdit(tester, court);
      await typeInto(tester, 'Precio por hora', '45000');

      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifies: the notice, the typed price stays and the space did not change.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.textContaining('45.000'), findsOneWidget);
      expect((await spaceAUserSees(court))?['price_per_hour'], 43000);

      // Verifies: with the network back, saving works.
      api.state = ApiState.normal;
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      expect((await spaceAUserSees(court))?['price_per_hour'], 45000);
      semantics.dispose();
    },
  );

  testWidgets(
    'from the edit screen it goes on to deactivate the space @CU-22-H07-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final court = await oneSpace();
      await signInAsAdmin(tester);
      await openEdit(tester, court);

      await tapText(tester, 'DAR DE BAJA EL ESPACIO');

      // Verifies: the deactivation confirmation, with the space being edited.
      await waitUntil(tester, find.text('¿Dar de baja el espacio?'));
      expect(find.text('$court. La acción es permanente.'), findsOneWidget);
      semantics.dispose();
    },
  );
}
