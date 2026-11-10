import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final today = todayAtClub();
  DateTime day(int days) => today.add(Duration(days: days));

  const months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];
  const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  /// «Jue 12 de noviembre».
  String dateLabel(DateTime d) =>
      '${weekdays[d.weekday - 1]} ${d.day} de ${months[d.month - 1]}';

  /// A venue with a «Fútbol 5» and a clay «Tenis» court.
  Future<(String, String, String)> venueWithCourts() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    return (
      venue,
      await createSpace(venue),
      await createSpace(venue, sport: 'Tenis', kind: 'PDL'),
    );
  }

  Future<String> account() async {
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    return email;
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

  Future<void> openMyBookings(WidgetTester tester) async {
    await tapText(tester, 'RESERVAS');
    await waitUntil(tester, find.text('Mis reservas'));
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tapText(tester, 'Historial');
  }

  /// The on-screen order, top to bottom, of the texts that are found.
  List<String> inOrder(WidgetTester tester, List<String> texts) {
    final y = {
      for (final t in texts) t: tester.getTopLeft(find.text(t).first).dy,
    };
    return [...texts]..sort((a, b) => y[a]!.compareTo(y[b]!));
  }

  testWidgets(
    'opens «Mis reservas» and sees its upcoming bookings with venue, space, date, time and price @CU-08-H01-01',
    (tester) async {
      final (venue, f5, tennis) = await venueWithCourts();
      final email = await account();
      await occupy(tennis, day(3), 10, email: email);
      await occupy(f5, day(1), 18, hours: 2, email: email);
      await signIn(tester, email);

      await openMyBookings(tester);

      // Verifies: each upcoming one with its data, the nearest first.
      await waitUntil(tester, find.text(f5));
      expect(find.text(tennis), findsOneWidget);
      expect(find.text('$venue · Av. Vergara 1850'), findsNWidgets(2));
      expect(find.text(dateLabel(day(1))), findsOneWidget);
      expect(find.text('18:00 – 20:00'), findsOneWidget);
      expect(find.textContaining('86.000'), findsOneWidget);
      expect(find.text('ACTIVA'), findsNWidgets(2));
      expect(inOrder(tester, [f5, tennis]), [f5, tennis]);
    },
  );

  testWidgets('a booking just made shows up in «Próximas» @CU-08-H01-02', (
    tester,
  ) async {
    final (_, f5, _) = await venueWithCourts();
    final email = await account();
    await signIn(tester, email);
    await openMyBookings(tester);
    await waitUntil(tester, find.text('No hay próximas reservas'));

    await occupy(f5, day(2), 9, email: email);
    await tapText(tester, 'INICIO');
    await openMyBookings(tester);

    // Verifies: on returning to the section it is there.
    await waitUntil(tester, find.text(f5));
    expect(find.text('09:00 – 10:00'), findsOneWidget);
  });

  testWidgets(
    'opens «Historial» and sees its already finished bookings, ordered by date @CU-08-H01-03',
    (tester) async {
      final (_, f5, tennis) = await venueWithCourts();
      final email = await account();
      await occupy(f5, day(-6), 10, email: email);
      await occupy(tennis, day(-2), 19, email: email);
      await signIn(tester, email);
      await openMyBookings(tester);

      await openHistory(tester);

      // Verifies: both completed, the most recent first.
      await waitUntil(tester, find.text(tennis));
      expect(find.text(f5), findsOneWidget);
      expect(find.text('COMPLETADA'), findsNWidgets(2));
      expect(inOrder(tester, [f5, tennis]), [tennis, f5]);
    },
  );

  testWidgets(
    'a cancelled or voided booking shows in the history with its status @CU-08-H01-04',
    (tester) async {
      final (_, f5, tennis) = await venueWithCourts();
      final email = await account();
      await occupy(f5, day(2), 20, email: email, status: 'canceled');
      await occupy(
        tennis,
        day(-1),
        19,
        email: email,
        status: 'voided',
        reason: 'mantenimiento de la cancha',
      );
      await signIn(tester, email);
      await openMyBookings(tester);
      await waitUntil(tester, find.text('No hay próximas reservas'));

      await openHistory(tester);

      // Verifies: both with their status and the reason.
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text('ANULADA'), findsOneWidget);
      expect(
        find.text('Cancelada por vos · el horario quedó liberado'),
        findsOneWidget,
      );
      expect(
        find.text('Anulada por el administrador · mantenimiento de la cancha'),
        findsOneWidget,
      );
    },
  );

  testWidgets('does not see other users\' bookings @CU-08-H01-05', (
    tester,
  ) async {
    final (_, f5, tennis) = await venueWithCourts();
    final email = await account();
    final other = await account();
    await occupy(f5, day(1), 10, email: email);
    await occupy(tennis, day(1), 10, email: other);
    await occupy(tennis, day(-1), 10, email: other);
    await signIn(tester, email);

    await openMyBookings(tester);

    // Verifies: only its own, in both tabs.
    await waitUntil(tester, find.text(f5));
    expect(find.text(tennis), findsNothing);
    await openHistory(tester);
    await waitUntil(tester, find.text('No hay reservas pasadas'));
    expect(find.text(tennis), findsNothing);
  });

  testWidgets(
    'with no upcoming bookings, sees the notice that it has none @CU-08-H02-01',
    (tester) async {
      final (_, f5, _) = await venueWithCourts();
      final email = await account();
      await occupy(f5, day(-3), 10, email: email);
      await signIn(tester, email);

      await openMyBookings(tester);

      // Verifies: the «Próximas» notice.
      await waitUntil(tester, find.text('No hay próximas reservas'));
      expect(
        find.text('No se encontraron próximas reservas asociadas a tu cuenta.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'with no past bookings, sees the notice that it has none @CU-08-H02-02',
    (tester) async {
      final (_, f5, _) = await venueWithCourts();
      final email = await account();
      await occupy(f5, day(3), 10, email: email);
      await signIn(tester, email);
      await openMyBookings(tester);
      await waitUntil(tester, find.text(f5));

      await openHistory(tester);

      // Verifies: the «Historial» notice.
      await waitUntil(tester, find.text('No hay reservas pasadas'));
      expect(
        find.text('No se encontraron reservas pasadas asociadas a tu cuenta.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('with no connection, sees the connection error @CU-08-H03-01', (
    tester,
  ) async {
    final (_, f5, _) = await venueWithCourts();
    final email = await account();
    await occupy(f5, day(1), 10, email: email);
    final api = await ProxyApi.open();
    await signIn(tester, email, apiUrl: api.url);

    api.state = ApiState.offline;
    await tapText(tester, 'RESERVAS');

    // Verifies: the connection notice and, once closed, no booking.
    await waitUntil(tester, find.text('Error de conexión'));
    await tapText(tester, 'Volver');
    expect(find.text(f5), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });

  testWidgets('the server fails and no partial data is shown @CU-08-H03-02', (
    tester,
  ) async {
    final (_, f5, _) = await venueWithCourts();
    final email = await account();
    await occupy(f5, day(1), 10, email: email);
    await occupy(f5, day(-1), 10, email: email);
    final api = await ProxyApi.open();
    await signIn(tester, email, apiUrl: api.url);
    await openMyBookings(tester);
    await waitUntil(tester, find.text(f5));

    api.state = ApiState.failing;
    await openHistory(tester);

    // Verifies: the server error and no history card.
    await waitUntil(tester, find.text('Error del servidor'));
    await tapText(tester, 'ACEPTAR');
    expect(find.text('COMPLETADA'), findsNothing);
    expect(find.text(f5), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
