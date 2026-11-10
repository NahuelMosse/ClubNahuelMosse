import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openCreateForm(WidgetTester tester) async {
    await tapText(tester, 'SEDES');
    await waitUntil(tester, find.text('AGREGAR SEDE'));
    await tapText(tester, 'AGREGAR SEDE');
    await waitUntil(tester, find.text('Nueva sede'));
  }

  Future<void> fillIn(
    WidgetTester tester, {
    required String name,
    String address = 'Av. Vergara 1850',
  }) async {
    await typeInto(tester, 'Nombre de la sede', name);
    await typeInto(tester, 'Dirección', address);
    await chooseTime(tester, 'Horario de apertura', '08:00');
    await chooseTime(tester, 'Horario de cierre', '23:00');
  }

  testWidgets(
    'creates a venue with name, address and schedule, and it shows in the venue listing of the users @CU-17-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await signInAsAdmin(tester);
      await openCreateForm(tester);

      await fillIn(tester, name: name);
      await tapText(tester, 'GUARDAR SEDE');

      // Verifies: confirms the creation with the venue data.
      await waitUntil(tester, find.text('¡Sede creada!'));
      expect(find.text('$name · Av. Vergara 1850'), findsOneWidget);

      // Verifies: the panel listing shows it with its schedule.
      await tapText(tester, 'IR AL LISTADO');
      await waitUntil(tester, find.text(name));
      expect(
        find.bySemanticsLabel(
          RegExp(
            '^${RegExp.escape(name)}, Av\\. Vergara 1850, .*'
            'Lunes a domingo de 08:00 a 23:00',
          ),
        ),
        findsOneWidget,
      );

      // Verifies: a user already sees it in their venue listing.
      expect((await venuesAUserSees()).keys, contains(name));
      semantics.dispose();
    },
  );

  testWidgets(
    'the newly created venue shows with no courts until spaces are loaded @CU-17-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Castelar ${unique()}';
      await signInAsAdmin(tester);
      await openCreateForm(tester);
      await fillIn(tester, name: name, address: 'Av. Rivadavia 23500');
      await tapText(tester, 'GUARDAR SEDE');
      await waitUntil(tester, find.text('¡Sede creada!'));
      await tapText(tester, 'IR AL LISTADO');
      await waitUntil(tester, find.text(name));

      // Verifies: in the panel it appears with zero courts.
      expect(
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(name)}, Av\\. Rivadavia 23500, 0 canchas'),
        ),
        findsOneWidget,
      );
      // Verifies: the users also see it with no courts.
      expect((await venuesAUserSees())[name], 0);
      semantics.dispose();
    },
  );

  testWidgets(
    'from the success screen goes back to the listing or starts another creation with an empty form @CU-17-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final first = 'Sede Morón ${unique()}';
      final second = 'Sede Ituzaingó ${unique()}';
      await signInAsAdmin(tester);
      await openCreateForm(tester);
      await fillIn(tester, name: first, address: 'Av. Rivadavia 19850');
      await tapText(tester, 'GUARDAR SEDE');
      await waitUntil(tester, find.text('¡Sede creada!'));

      // Verifies: «Crear otra sede» opens the empty form.
      await tapText(tester, 'Crear otra sede');
      await waitUntil(tester, find.text('Nueva sede'));
      expect(find.text(first), findsNothing);
      expect(find.text('Av. Rivadavia 19850'), findsNothing);

      await fillIn(tester, name: second, address: 'Ratti 1400');
      await tapText(tester, 'GUARDAR SEDE');
      await waitUntil(tester, find.text('¡Sede creada!'));

      // Verifies: «IR AL LISTADO» goes back to the panel with the two new venues.
      await tapText(tester, 'IR AL LISTADO');
      await waitUntil(tester, find.text(second));
      expect(find.text(first), findsOneWidget);
      expect(find.text('AGREGAR SEDE'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('goes back from the form and nothing is created @CU-17-H02-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final name = 'Sede Haedo ${unique()}';
    await signInAsAdmin(tester);
    await openCreateForm(tester);
    await fillIn(tester, name: name);

    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();

    // Verifies: back to the listing without the venue and it was not saved.
    await waitUntil(tester, find.text('AGREGAR SEDE'));
    expect(find.text('Nueva sede'), findsNothing);
    expect(find.text(name), findsNothing);
    expect((await venuesAUserSees()).keys, isNot(contains(name)));
    semantics.dispose();
  });

  testWidgets(
    'tries to save without an address or without a schedule and the required fields are marked @CU-17-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await signInAsAdmin(tester);
      await openCreateForm(tester);
      await typeInto(tester, 'Nombre de la sede', name);
      await chooseTime(tester, 'Horario de apertura', '08:00');

      await tapText(tester, 'GUARDAR SEDE');

      // Verifies: does not submit and marks each missing field.
      expect(find.text('La dirección es obligatoria'), findsOneWidget);
      expect(find.text('El horario de cierre es obligatorio'), findsOneWidget);
      expect(find.text('¡Sede creada!'), findsNothing);
      expect((await venuesAUserSees()).keys, isNot(contains(name)));
      semantics.dispose();
    },
  );

  testWidgets(
    'with no connection or the server down on saving, sees the error and keeps what was entered @CU-17-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await openCreateForm(tester);
      await fillIn(tester, name: name);

      // Verifies: with the server down it warns and what was entered stays in the form.
      api.state = ApiState.failing;
      await tapText(tester, 'GUARDAR SEDE');
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text(name), findsOneWidget);
      expect(find.text('Av. Vergara 1850'), findsOneWidget);

      // Verifies: with no connection it warns, and on retrying with the network back it saves.
      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR SEDE');
      await waitUntil(tester, find.text('Error de conexión'));
      api.state = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.text('¡Sede creada!'));
      expect((await venuesAUserSees()).keys, contains(name));
      semantics.dispose();
    },
  );
}
