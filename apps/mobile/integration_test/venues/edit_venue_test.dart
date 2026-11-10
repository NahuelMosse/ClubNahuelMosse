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

  /// From the panel to the edit screen of the venue [name].
  Future<void> openEdit(WidgetTester tester, String name) async {
    await tapText(tester, 'SEDES');
    await waitUntil(tester, find.text('AGREGAR SEDE'));
    await tapLabel(tester, 'Editar sede $name');
    await waitUntil(tester, find.text('Editar sede'));
  }

  testWidgets(
    'changes the address of a venue and the user listing shows the new one @CU-18-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await typeInto(tester, 'Dirección', 'Av. Vergara 1900');
      await tapText(tester, 'GUARDAR CAMBIOS');

      // Verifies: the notice, and the panel listing with the new address.
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      await waitUntil(
        tester,
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(name)}, Av\\. Vergara 1900, '),
        ),
      );
      // Verifies: a user sees the venue with the new address.
      expect((await venueAUserSees(name))?['address'], 'Av. Vergara 1900');
      semantics.dispose();
    },
  );

  testWidgets(
    'after editing, the existing bookings stay associated with the venue @CU-18-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final court = await createSpace(name);
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: 'ClubNahuel1');
      await occupy(court, tomorrow, 21, email: email);
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await typeInto(tester, 'Nombre de la sede', '$name Norte');
      await typeInto(tester, 'Dirección', 'Av. Vergara 1900');
      await tapText(tester, 'GUARDAR CAMBIOS');
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );

      // Verifies: the booking stays, on the same court, under its usual name.
      expect(await bookingsOf(email), [(court, '21:00')]);
      expect((await venueAUserSees('$name Norte'))?['space_count'], 1);
      semantics.dispose();
    },
  );

  testWidgets('goes back without saving and nothing changes @CU-18-H02-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final name = 'Sede Haedo ${unique()}';
    await createVenue(name, 'Av. Vergara 1850');
    await signInAsAdmin(tester);
    await openEdit(tester, name);
    await typeInto(tester, 'Dirección', 'Av. Vergara 1900');

    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();

    // Verifies: the listing and the API keep the previous address.
    await waitUntil(tester, find.text('AGREGAR SEDE'));
    expect(
      find.bySemanticsLabel(
        RegExp('^${RegExp.escape(name)}, Av\\. Vergara 1850, '),
      ),
      findsOneWidget,
    );
    expect((await venueAUserSees(name))?['address'], 'Av. Vergara 1850');
    semantics.dispose();
  });

  testWidgets(
    'empties the address, sees the required notice and cannot save @CU-18-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await typeInto(tester, 'Dirección', '');

      // Verifies: the notice on the field and «GUARDAR CAMBIOS» disabled.
      expect(find.text('La dirección es obligatoria'), findsOneWidget);
      expect(flags(tester, 'GUARDAR CAMBIOS').isEnabled, isFalse);
      expect((await venueAUserSees(name))?['address'], 'Av. Vergara 1850');
      semantics.dispose();
    },
  );

  testWidgets(
    'shrinks the schedule with bookings outside it, sees how many, confirms, and those bookings are kept @CU-18-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Morón ${unique()}';
      await createVenue(name, 'Av. Rivadavia 19850');
      final first = await createSpace(name);
      final second = await createSpace(name);
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: 'ClubNahuel1');
      await occupy(first, tomorrow, 8, email: email);
      await occupy(second, tomorrow, 8, email: email);
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await chooseTime(tester, 'Horario de apertura', '09:00');
      await tapText(tester, 'GUARDAR CAMBIOS');

      // Verifies: the notice says how many bookings fall outside.
      await waitUntil(tester, find.text('¿Guardar el horario nuevo?'));
      expect(
        find.textContaining(
          '2 reservas futuras de $name empiezan antes de las 09:00',
        ),
        findsOneWidget,
      );
      await tapText(tester, 'GUARDAR IGUAL');

      // Verifies: the schedule was saved and both bookings stay as they were.
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      expect((await venueAUserSees(name))?['opens_at'], '09:00');
      expect((await bookingsOf(email)).toSet(), {
        (first, '08:00'),
        (second, '08:00'),
      });
      semantics.dispose();
    },
  );

  testWidgets(
    'after shrinking the schedule, booking outside the new range is no longer possible @CU-18-H04-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Morón ${unique()}';
      await createVenue(name, 'Av. Rivadavia 19850');
      final court = await createSpace(name);
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await chooseTime(tester, 'Horario de apertura', '10:00');
      await chooseTime(tester, 'Horario de cierre', '20:00');
      await tapText(tester, 'GUARDAR CAMBIOS');
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );

      // Verifies: tomorrow's grid runs from 10 to 19, nothing before or after.
      final free = await freeStarts(court, tomorrow);
      expect(free.first, '10:00');
      expect(free.last, '19:00');
      expect(free, isNot(contains('08:00')));
      expect(free, isNot(contains('20:00')));
      semantics.dispose();
    },
  );

  testWidgets(
    'chooses to review the schedule and nothing is saved @CU-18-H04-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Morón ${unique()}';
      await createVenue(name, 'Av. Rivadavia 19850');
      final court = await createSpace(name);
      await occupy(court, tomorrow, 22);
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await chooseTime(tester, 'Horario de cierre', '22:00');
      await tapText(tester, 'GUARDAR CAMBIOS');
      await waitUntil(tester, find.text('¿Guardar el horario nuevo?'));
      expect(
        find.textContaining(
          '1 reserva futura de $name termina después de las 22:00',
        ),
        findsOneWidget,
      );

      await tapText(tester, 'REVISAR EL HORARIO');

      // Verifies: stays on the edit screen with what was picked and the venue did not change.
      expect(find.text('Editar sede'), findsOneWidget);
      expect(find.text('22:00'), findsOneWidget);
      expect((await venueAUserSees(name))?['closes_at'], '23:00');
      semantics.dispose();
    },
  );

  testWidgets(
    'the venue was deactivated in another session and is told so on saving @CU-18-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await openEdit(tester, name);
      await typeInto(tester, 'Dirección', 'Av. Vergara 1900');

      await deactivateVenueFromAnotherSession(name);
      await tapText(tester, 'GUARDAR CAMBIOS');

      // Verifies: the notice and the listing without that venue.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('AGREGAR SEDE'));
      expect(find.text(name), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'with no connection on saving, sees the error and keeps what was typed @CU-18-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      final api = await ProxyApi.open();
      await signInAsAdmin(tester, apiUrl: api.url);
      await openEdit(tester, name);
      await typeInto(tester, 'Dirección', 'Av. Vergara 1900');

      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR CAMBIOS');

      // Verifies: the notice, what was typed stays and the venue did not change.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('Av. Vergara 1900'), findsOneWidget);
      expect((await venueAUserSees(name))?['address'], 'Av. Vergara 1850');

      // Verifies: with the network back, saving works.
      api.state = ApiState.normal;
      await tapText(tester, 'GUARDAR CAMBIOS');
      await waitUntil(
        tester,
        find.text('Los cambios se guardaron correctamente'),
      );
      expect((await venueAUserSees(name))?['address'], 'Av. Vergara 1900');
      semantics.dispose();
    },
  );

  testWidgets(
    'from the edit screen goes on to deactivate the venue @CU-18-H07-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final name = 'Sede Haedo ${unique()}';
      await createVenue(name, 'Av. Vergara 1850');
      await signInAsAdmin(tester);
      await openEdit(tester, name);

      await tapText(tester, 'DAR DE BAJA LA SEDE');

      // Verifies: the deactivation confirmation, with the venue being edited.
      await waitUntil(tester, find.text('¿Dar de baja la sede?'));
      expect(find.textContaining('$name · Av. Vergara 1850'), findsOneWidget);
      semantics.dispose();
    },
  );
}
