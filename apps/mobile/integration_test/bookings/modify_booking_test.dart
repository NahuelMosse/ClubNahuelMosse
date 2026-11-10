import 'dart:ui' show SemanticsFlags;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];
  final tomorrow = todayAtClub().add(const Duration(days: 1));

  String slot(int hour) {
    String two(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
    return '${two(hour)} – ${two(hour + 1)}';
  }

  /// A venue with two Fútbol 5 and a booking of the new account on «Cancha 1», tomorrow at
  /// 21.
  Future<(String, String, String)> tomorrowBooking() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    final court = await createSpace(venue);
    await createSpace(venue);
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    await occupy(court, tomorrow, 21, email: email);
    return (venue, court, email);
  }

  Future<void> signIn(
    WidgetTester tester,
    String email, {
    String? apiUrl,
  }) async {
    await openApp(tester, apiUrl: apiUrl);
    await typeInto(tester, 'Correo', email);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

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

  /// From «Mis reservas» to the grid to modify the booking of [court].
  Future<void> openModify(WidgetTester tester, String court) async {
    await tapText(tester, 'RESERVAS');
    await waitUntil(tester, find.text(court));
    await tapText(tester, 'MODIFICAR');
    await waitUntil(tester, find.textContaining('Estás modifying tu reserva'));
  }

  /// Picks the 19 slot and reaches «Confirmá el cambio».
  Future<void> goToConfirm(WidgetTester tester) async {
    await tapLabel(tester, slot(19));
    await tapText(tester, 'CONTINUAR CON EL CAMBIO');
    await waitUntil(tester, find.text('Confirmá el cambio'));
  }

  testWidgets(
    'changes the time and the booking, with the same identifier, shows the new time @CU-11-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      final before = await bookingNumbers(email);
      await signIn(tester, email);
      await openModify(tester, court);
      await goToConfirm(tester);
      expect(find.text('ANTES'), findsOneWidget);
      expect(find.textContaining(slot(21)), findsWidgets);
      expect(find.textContaining(slot(19)), findsWidgets);

      await tapText(tester, 'GUARDAR EL CAMBIO');

      // Verifies: «Mis reservas» shows the new time on the same booking.
      await waitUntil(tester, find.text('Reserva modificada'));
      await waitUntil(tester, find.text(slot(19)));
      expect(find.text(slot(21)), findsNothing);
      expect(await bookingNumbers(email), before);
      expect(await bookingsOf(email), [(court, '19:00')]);
      semantics.dispose();
    },
  );

  testWidgets(
    'after the change, the previous time is free for others and the new one taken @CU-11-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openModify(tester, court);
      await goToConfirm(tester);
      await tapText(tester, 'GUARDAR EL CAMBIO');
      await waitUntil(tester, find.text('Reserva modificada'));

      // Another person looks at the times of «Cancha 1».
      final other = 'socio.${unique()}@correo.com';
      await createAccount(email: other, password: 'ClubNahuel1');
      await signIn(tester, other);
      await tapText(tester, 'SEDES');
      final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(venue)},'));
      await waitUntil(tester, card);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('VER HORARIOS / RESERVAR').first);
      await tester.pumpAndSettle();
      await tapLabel(tester, '${days[tomorrow.weekday - 1]} ${tomorrow.day}');

      // Verifies: the 21 is free and the 19 taken.
      expect(flags(tester, slot(21)).isEnabled, isTrue);
      expect(flags(tester, slot(19)).isEnabled, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'backs out with «Dejar la reserva como está» and nothing changes @CU-11-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openModify(tester, court);
      await goToConfirm(tester);

      await tapText(tester, 'DEJAR LA RESERVA COMO ESTÁ');

      // Verifies: back on «Mis reservas» with the booking at its time.
      await waitUntil(tester, find.text(slot(21)));
      expect(await bookingsOf(email), [(court, '21:00')]);
      semantics.dispose();
    },
  );

  testWidgets(
    'the new time was taken while picking: it is rejected and the original booking stays intact @CU-11-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openModify(tester, court);
      await goToConfirm(tester);

      // While confirming, another person takes the 19.
      await occupy(court, tomorrow, 19);
      await tapText(tester, 'GUARDAR EL CAMBIO');

      // Verifies: the notice, the refreshed grid and the booking where it was.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(
        tester,
        find.textContaining('Estás modifying tu reserva'),
      );
      expect(flags(tester, slot(19)).isEnabled, isFalse);
      expect(await bookingsOf(email), [(court, '21:00')]);
      semantics.dispose();
    },
  );

  testWidgets(
    'without picking a different time, the button stays disabled @CU-11-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);

      await openModify(tester, court);

      // Verifies: with the current time picked it cannot continue.
      expect(flags(tester, 'CONTINUAR CON EL CAMBIO').isEnabled, isFalse);
      await tapLabel(tester, slot(19));
      expect(flags(tester, 'CONTINUAR CON EL CAMBIO').isEnabled, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'the booking already started and is told it cannot be modified @CU-11-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openModify(tester, court);
      await goToConfirm(tester);

      // While confirming, the turn starts.
      await startBookingsOf(court);
      await tapText(tester, 'GUARDAR EL CAMBIO');

      // Verifies: the notice and, in «Mis reservas», modifying it is no longer offered.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text(court));
      expect(find.text('MODIFICAR'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the booking was voided by an administrator and is told it cannot be modified @CU-11-H05-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openModify(tester, court);
      await goToConfirm(tester);

      // While confirming, the club voids it.
      await voidBookingsOf(court);
      await tapText(tester, 'GUARDAR EL CAMBIO');

      // Verifies: the notice and the booking out of the upcoming ones.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('No hay próximas reservas'));
      expect(await bookingsOf(email), isEmpty);
      semantics.dispose();
    },
  );

  testWidgets(
    'with no connection or the server down on saving, the booking stays as it was @CU-11-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (_, court, email) = await tomorrowBooking();
      final api = await ProxyApi.open();
      await signIn(tester, email, apiUrl: api.url);
      await openModify(tester, court);
      await goToConfirm(tester);

      api.state = ApiState.offline;
      await tapText(tester, 'GUARDAR EL CAMBIO');

      // Verifies: with no connection, the notice and the booking intact.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('Confirmá el cambio'), findsOneWidget);
      expect(await bookingsOf(email), [(court, '21:00')]);

      api.state = ApiState.failing;
      await tapText(tester, 'GUARDAR EL CAMBIO');

      // Verifies: with the server down, the same.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(await bookingsOf(email), [(court, '21:00')]);
      semantics.dispose();
    },
  );
}
