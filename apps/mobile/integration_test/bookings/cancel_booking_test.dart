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

  /// A venue with a Fútbol 5 and a booking of the new account tomorrow at 21.
  Future<(String, String, String)> tomorrowBooking() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    final court = await createSpace(venue);
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

  Future<void> openMyBookings(WidgetTester tester, String court) async {
    await tapText(tester, 'RESERVAS');
    await waitUntil(tester, find.text(court));
  }

  Future<void> requestCancel(WidgetTester tester) async {
    await tapText(tester, 'CANCELAR');
    await waitUntil(tester, find.text('¿Cancelar la reserva?'));
  }

  SemanticsFlags flags(WidgetTester tester, String label) =>
      tester.getSemantics(find.bySemanticsLabel(label)).flagsCollection;

  testWidgets(
    'cancels a future booking, sees the success and the booking moves to the history as cancelled @CU-10-H01-01',
    (tester) async {
      final (venue, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openMyBookings(tester, court);
      await requestCancel(tester);
      expect(find.textContaining(venue), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);

      await tapText(tester, 'CANCELAR RESERVA');

      // Verifies: the success, the booking leaves «Próximas» and is in the history.
      await waitUntil(tester, find.text('Reserva cancelada con éxito'));
      await tapText(tester, 'ACEPTAR');
      await waitUntil(tester, find.text('No hay próximas reservas'));
      await tapText(tester, 'Historial');
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text(court), findsOneWidget);
      expect(await bookingsOf(email), isEmpty);
    },
  );

  testWidgets(
    'after cancelling, another user can book that same time @CU-10-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openMyBookings(tester, court);
      await requestCancel(tester);
      await tapText(tester, 'CANCELAR RESERVA');
      await waitUntil(tester, find.text('Reserva cancelada con éxito'));

      // Another person looks at the times of that court.
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
      await tapText(tester, 'VER HORARIOS / RESERVAR');
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      final chip = find.bySemanticsLabel(
        '${days[tomorrow.weekday - 1]} ${tomorrow.day}',
      );
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();

      // Verifies: the 21 one is free again.
      expect(flags(tester, '21:00 – 22:00').isEnabled, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'backs out on the confirmation and the booking stays active and the time taken @CU-10-H02-01',
    (tester) async {
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openMyBookings(tester, court);
      await requestCancel(tester);

      await tapText(tester, 'NO CANCELAR');

      // Verifies: stays in «Próximas», active, and the API has it.
      expect(find.text('¿Cancelar la reserva?'), findsNothing);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(await bookingsOf(email), [(court, '21:00')]);
    },
  );

  testWidgets(
    'with no connection on confirming, sees the error with retry and the booking stays active @CU-10-H03-01',
    (tester) async {
      final (_, court, email) = await tomorrowBooking();
      final api = await ProxyApi.open();
      await signIn(tester, email, apiUrl: api.url);
      await openMyBookings(tester, court);
      await requestCancel(tester);

      api.state = ApiState.offline;
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifies: the notice with retry and the booking intact.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      await tapText(tester, 'Volver');
      expect(await bookingsOf(email), [(court, '21:00')]);
    },
  );

  testWidgets(
    'the server fails on cancelling and the booking stays active @CU-10-H04-01',
    (tester) async {
      final (_, court, email) = await tomorrowBooking();
      final api = await ProxyApi.open();
      await signIn(tester, email, apiUrl: api.url);
      await openMyBookings(tester, court);
      await requestCancel(tester);

      api.state = ApiState.failing;
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifies: the server notice and the booking intact.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text(court), findsOneWidget);
      expect(await bookingsOf(email), [(court, '21:00')]);
    },
  );

  testWidgets(
    'tries to cancel a booking that already started and is told it cannot be done @CU-10-H05-01',
    (tester) async {
      final (_, court, email) = await tomorrowBooking();
      await signIn(tester, email);
      await openMyBookings(tester, court);
      await requestCancel(tester);

      // While looking at the confirmation, the turn starts.
      await startBookingsOf(court);
      await tapText(tester, 'CANCELAR RESERVA');

      // Verifies: the notice that it changed and, once refreshed, it can no longer be cancelled.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text(court));
      expect(find.text('CANCELAR'), findsNothing);
      expect(await bookingsOf(email), hasLength(1));
    },
  );
}
