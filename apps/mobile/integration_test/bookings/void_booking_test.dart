import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tomorrow = todayAtClub().add(const Duration(days: 1));
  const reason = 'Mantenimiento urgente del césped sintético.';

  /// A venue with a Fútbol 5 and a booking of a new account tomorrow at 21.
  Future<(String, String, String)> tomorrowBooking() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    final court = await createSpace(venue);
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    await occupy(court, tomorrow, 21, email: email);
    return (venue, court, email);
  }

  /// The administrator enters the panel and leaves in view only the booking of [venue].
  Future<void> openPanel(
    WidgetTester tester,
    String venue,
    String court, {
    String? apiUrl,
  }) async {
    await signInAsAdmin(tester, apiUrl: apiUrl);
    await typeInto(tester, 'Buscar reserva', venue);
    await waitUntil(tester, find.text(court));
  }

  Future<void> requestVoid(WidgetTester tester) async {
    await tapText(tester, 'ANULAR RESERVA');
    await waitUntil(tester, find.text('¿Anular esta reserva?'));
  }

  Future<void> confirmWithReason(WidgetTester tester) async {
    await typeInto(tester, 'Motivo de la anulación', reason);
    await tapText(tester, 'CONFIRMAR ANULACIÓN');
  }

  testWidgets(
    'voids an active booking with a reason and it ends up voided with reason, date, time and administrator @CU-15-H01-01',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);
      expect(find.text('Nahuel Mosse'), findsWidgets);
      expect(find.textContaining(venue), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);

      await confirmWithReason(tester);

      // Verifies: the notice, the voided card and the full trail in the API.
      await waitUntil(tester, find.text('Reserva anulada correctamente'));
      await tapText(tester, 'ACEPTAR');
      await waitUntil(tester, find.text('ANULADA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      final booking = await bookingAdminSees(court);
      expect(booking?['status'], 'voided');
      expect(booking?['reason'], reason);
      expect(booking?['canceled_at'], isNotNull);
      expect(booking?['canceled_by_name'], isNotNull);
    },
  );

  testWidgets(
    'after voiding, another user can book that same time @CU-15-H01-02',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);
      await confirmWithReason(tester);
      await waitUntil(tester, find.text('Reserva anulada correctamente'));

      // Verifies: the 21 is free again and another account books it.
      expect(await freeStarts(court, tomorrow), contains('21:00'));
      final other = 'socio.${unique()}@correo.com';
      await createAccount(email: other, password: 'ClubNahuel1');
      expect(await bookThroughApi(other, court, tomorrow, 21), greaterThan(0));
    },
  );

  testWidgets(
    'the affected user sees the voided booking in their history with the reason @CU-15-H01-03',
    (tester) async {
      final (venue, court, email) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);
      await confirmWithReason(tester);
      await waitUntil(tester, find.text('Reserva anulada correctamente'));

      await openApp(tester);
      await typeInto(tester, 'Correo', email);
      await typeInto(tester, 'Contraseña', 'ClubNahuel1');
      await tapText(tester, 'INICIAR SESIÓN');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      // The voiding already generated its notice (CU-24.2): the panel opens by itself on
      // entering and covers the screen until it is closed.
      await waitUntil(tester, find.text('El club anuló tu reserva'));
      await tester.tap(find.bySemanticsLabel('Cerrar las notificaciones'));
      await tester.pumpAndSettle();
      await tapText(tester, 'RESERVAS');
      await tapText(tester, 'Historial');

      // Verifies: it shows as voided, with the reason the administrator wrote.
      await waitUntil(tester, find.text('ANULADA'));
      expect(find.text(court), findsOneWidget);
      expect(find.textContaining(reason), findsOneWidget);
      expect(await historyOf(email), [(court, 'voided', reason)]);
    },
  );

  testWidgets(
    'goes back from the confirmation and the booking stays active @CU-15-H02-01',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);

      await tapText(tester, 'VOLVER');

      // Verifies: back to the listing, the booking did not change and can be voided again.
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ACTIVA'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect((await bookingAdminSees(court))?['status'], 'active');
    },
  );

  testWidgets(
    'confirms without a reason, sees it is required and the booking is not voided @CU-15-H03-01',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);

      await tapText(tester, 'CONFIRMAR ANULACIÓN');

      // Verifies: the field notice, the confirmation stays open and the API saw nothing.
      await waitUntil(
        tester,
        find.text('El motivo es obligatorio para anular'),
      );
      expect(find.text('¿Anular esta reserva?'), findsOneWidget);
      expect((await bookingAdminSees(court))?['status'], 'active');
    },
  );

  testWidgets(
    'the user cancelled the booking in the meantime and the voiding is rejected @CU-15-H04-01',
    (tester) async {
      final (venue, court, email) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);

      await cancelUpcomingOf(email);
      await confirmWithReason(tester);

      // Verifies: the notice that it changed, the refreshed listing and the cancellation intact.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      final booking = await bookingAdminSees(court);
      expect(booking?['status'], 'canceled');
      expect(booking?['reason'], isNull);
    },
  );

  testWidgets(
    'the booking already started and the voiding is rejected @CU-15-H04-02',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      await openPanel(tester, venue, court);
      await requestVoid(tester);

      await startBookingsOf(court);
      await confirmWithReason(tester);

      // Verifies: the notice, the listing no longer offers voiding and the booking stays active.
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await waitUntil(tester, find.text('ACTIVA'));
      expect(find.text('ANULAR RESERVA'), findsNothing);
      expect((await bookingAdminSees(court))?['status'], 'active');
    },
  );

  testWidgets(
    'with no connection on confirming, sees the error with retry and the booking stays active @CU-15-H05-01',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      final api = await ProxyApi.open();
      await openPanel(tester, venue, court, apiUrl: api.url);
      await requestVoid(tester);

      api.state = ApiState.offline;
      await confirmWithReason(tester);

      // Verifies: the notice with retry, and on going back the booking keeps its status.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      await tapText(tester, 'Volver');
      expect(find.text('ACTIVA'), findsOneWidget);
      expect((await bookingAdminSees(court))?['status'], 'active');
    },
  );

  testWidgets(
    'the server fails on voiding and the booking stays active @CU-15-H05-01',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      final api = await ProxyApi.open();
      await openPanel(tester, venue, court, apiUrl: api.url);
      await requestVoid(tester);

      api.state = ApiState.failing;
      await confirmWithReason(tester);

      // Verifies: the server notice and the booking intact.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('ACTIVA'), findsOneWidget);
      expect((await bookingAdminSees(court))?['status'], 'active');
    },
  );

  testWidgets(
    'retries after the outage and the booking ends up voided only once @CU-15-H05-01',
    (tester) async {
      final (venue, court, _) = await tomorrowBooking();
      final api = await ProxyApi.open();
      await openPanel(tester, venue, court, apiUrl: api.url);
      await requestVoid(tester);

      api.state = ApiState.offline;
      await confirmWithReason(tester);
      await waitUntil(tester, find.text('Error de conexión'));
      api.state = ApiState.normal;
      await tapText(tester, 'REINTENTAR');

      // Verifies: the success notice and the trail with the written reason.
      await waitUntil(tester, find.text('Reserva anulada correctamente'));
      await tapText(tester, 'ACEPTAR');
      await waitUntil(tester, find.text('ANULADA'));
      final booking = await bookingAdminSees(court);
      expect(booking?['status'], 'voided');
      expect(booking?['reason'], reason);
    },
  );
}
