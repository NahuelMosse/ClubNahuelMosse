import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const duplicate =
      'Ya existe un espacio deportivo con ese nombre en la sede seleccionada.';

  /// A venue owned by the test and the part of the composed name that belongs to it.
  Future<(String, String)> ownVenue() async {
    final s = unique();
    await createVenue('Sede Haedo $s', 'Av. Vergara 1850');
    return ('Sede Haedo $s', 'Haedo${s}_Vergara_1850');
  }

  Future<void> openCreate(WidgetTester tester) async {
    await tapText(tester, 'ESPACIOS');
    await waitUntil(tester, find.text('ALTA ESPACIO'));
    await tapText(tester, 'ALTA ESPACIO');
    await waitUntil(tester, find.text('Nuevo espacio deportivo'));
  }

  Future<void> fillIn(
    WidgetTester tester,
    String venue, {
    String kind = 'Fútbol 5',
  }) async {
    await choose(tester, 'Sede', venue);
    await choose(tester, 'Deporte', 'Fútbol');
    await choose(tester, 'Tipo', kind);
    await choose(tester, 'Condición', 'Al aire libre');
    await choose(tester, 'Iluminación', 'Iluminada');
    await typeInto(tester, 'Precio por hora', '38000');
  }

  testWidgets(
    'creates a space with venue, sport, kind and price, and users see it in the venue @CU-21-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      await signInAsAdmin(tester);
      await openCreate(tester);

      await fillIn(tester, venue);
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifies: it confirms the creation with the name of the space.
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));
      expect(find.text('${prefix}_Futbol_F5_1'), findsOneWidget);

      // Verifies: a user already sees it among the available spaces.
      expect(await spacesAUserSees(), contains('${prefix}_Futbol_F5_1'));
      expect((await venuesAUserSees())[venue], 1);
      semantics.dispose();
    },
  );

  testWidgets(
    'the name is built only from the venue, the address, the sport, the kind and the next free number @CU-21-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      await createSpace(venue);
      await signInAsAdmin(tester);
      await openCreate(tester);

      // Verifies: without venue, sport and kind there is no name yet.
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);

      // Verifies: with a Fútbol 5 already loaded in the venue, the next one is 2.
      await fillIn(tester, venue);
      await waitUntil(tester, find.text('${prefix}_Futbol_F5_2'));

      // Verifies: another kind starts its own numbering.
      await choose(tester, 'Tipo', 'Fútbol 7');
      await waitUntil(tester, find.text('${prefix}_Futbol_F7_1'));
      semantics.dispose();
    },
  );

  testWidgets(
    'from the success it returns to the listing or starts another creation with the form empty @CU-21-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      await signInAsAdmin(tester);
      await openCreate(tester);
      await fillIn(tester, venue);
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));

      // Verifies: «Crear otro» opens the empty form.
      await tapText(tester, 'Crear otro');
      await waitUntil(tester, find.text('Nuevo espacio deportivo'));
      expect(find.text('Completá sede, deporte y tipo'), findsOneWidget);
      expect(find.text(venue), findsNothing);

      await fillIn(tester, venue, kind: 'Fútbol 7');
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));

      // Verifies: «IR AL LISTADO» returns to the panel with the two new spaces.
      await tapText(tester, 'IR AL LISTADO');
      await waitUntil(tester, find.text('${prefix}_Futbol_F7_1'));
      expect(find.text('${prefix}_Futbol_F5_1'), findsOneWidget);
      expect(find.text('ALTA ESPACIO'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the calculated name already exists on saving: it sees the error and the number is recalculated @CU-21-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      await signInAsAdmin(tester);
      await openCreate(tester);
      await fillIn(tester, venue);
      await waitUntil(tester, find.text('${prefix}_Futbol_F5_1'));

      // Another administrator loads the same kind in the same venue meanwhile.
      await createSpace(venue);
      await tapText(tester, 'GUARDAR ESPACIO');

      // Verifies: it warns of the duplicate and the name moves to the next number.
      await waitUntil(tester, find.text(duplicate));
      await waitUntil(tester, find.text('${prefix}_Futbol_F5_2'));
      expect(find.text('¡Espacio deportivo creado!'), findsNothing);

      // Verifies: on saving again, it ends up with the new number.
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));
      expect(find.text('${prefix}_Futbol_F5_2'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('a required field is missing and it cannot save @CU-21-H03-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (venue, prefix) = await ownVenue();
    await signInAsAdmin(tester);
    await openCreate(tester);
    await choose(tester, 'Sede', venue);
    await choose(tester, 'Deporte', 'Fútbol');
    await choose(tester, 'Condición', 'Al aire libre');
    await choose(tester, 'Iluminación', 'Iluminada');
    await typeInto(tester, 'Precio por hora', '38000');

    await tapText(tester, 'GUARDAR ESPACIO');

    // Verifies: it flags the kind as required and nothing is created.
    expect(find.text('Este campo es obligatorio'), findsOneWidget);
    expect(find.text('¡Espacio deportivo creado!'), findsNothing);
    expect(
      (await spacesAUserSees()).where((n) => n.startsWith(prefix)),
      isEmpty,
    );
    semantics.dispose();
  });

  testWidgets(
    'offline or with the server down on saving, it sees the error and keeps what was loaded @CU-21-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await openCreate(tester);
      await fillIn(tester, venue);
      await waitUntil(tester, find.text('${prefix}_Futbol_F5_1'));

      // Verifies: with the server down it warns and what was loaded stays on the form.
      api.state = ApiState.failing;
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text(venue), findsOneWidget);
      expect(find.text('${prefix}_Futbol_F5_1'), findsOneWidget);

      // Verifies: offline it warns, and on retrying with the network back it saves.
      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('Error de conexión'));
      api.state = ApiState.normal;
      await tapText(tester, 'REINTENTAR');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));
      expect(await spacesAUserSees(), contains('${prefix}_Futbol_F5_1'));
      semantics.dispose();
    },
  );
}
