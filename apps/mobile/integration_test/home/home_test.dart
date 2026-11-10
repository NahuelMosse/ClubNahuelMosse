import 'package:clubnahuelmosse/common/club_timezone.dart';
import 'package:clubnahuelmosse/features/home/presentation/home_greeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tomorrow = todayAtClub().add(const Duration(days: 1));
  final inFiveDays = todayAtClub().add(const Duration(days: 5));

  /// Waits for [text] to leave the screen: the Home has just reloaded.
  Future<void> waitUntilGone(WidgetTester tester, String text) async {
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(end) &&
        find.text(text).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(text), findsNothing);
  }

  testWidgets('on signing in it sees the Home with the greeting and its name'
      ' @TP-01-H01-01', (tester) async {
    await signInAsUser(
      tester,
      email: 'socio.${unique()}@correo.com',
      name: 'Valentina',
    );

    // Verifies: the greeting for the club's hour and the name of whoever signed in.
    expect(find.text(HomeGreeting.forHour(clubNow())), findsOneWidget);
    expect(find.text('Valentina'), findsOneWidget);
  });

  testWidgets(
    'the Home shows its next active booking, the closest one, with date,'
    ' time and venue @TP-01-H01-02 @assumption:TP-01-SUP-05',
    (tester) async {
      final venue = 'Sede Haedo ${unique()}';
      await createVenue(venue, 'Av. Vergara 1850');
      final court = await createSpace(venue);
      final otherCourt = await createSpace(venue, kind: 'F7');
      final email = 'socio.${unique()}@correo.com';
      await createAccount(email: email, password: 'ClubNahuel1');
      // Two upcoming bookings: tomorrow's has to beat the one in five days.
      await occupy(otherCourt, inFiveDays, 10, email: email);
      await occupy(court, tomorrow, 21, email: email);

      await signInAsUser(tester, email: email);

      // Verifies: the closest one (tomorrow) is shown, with its venue and time.
      await waitUntil(tester, find.text('TU PRÓXIMA RESERVA'));
      expect(find.text(court), findsOneWidget);
      expect(find.textContaining(venue), findsWidgets);
      expect(find.textContaining('21:00 – 22:00'), findsWidgets);
      expect(find.text(otherCourt), findsNothing);
    },
  );

  testWidgets('from the next booking it can modify or cancel it @TP-01-H01-03', (
    tester,
  ) async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    final court = await createSpace(venue);
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    await occupy(court, tomorrow, 21, email: email);

    await signInAsUser(tester, email: email);
    await waitUntil(tester, find.text('MODIFICAR'));
    expect(find.text('CANCELAR'), findsOneWidget);

    await tapText(tester, 'CANCELAR');
    await waitUntil(tester, find.text('¿Cancelar la reserva?'));
    await tapText(tester, 'CANCELAR RESERVA');

    // Verifies: the success and that the next booking block disappears from the Home.
    await waitUntil(tester, find.text('Reserva cancelada con éxito'));
    await tapText(tester, 'ACEPTAR');
    await waitUntilGone(tester, 'TU PRÓXIMA RESERVA');
    expect(await bookingsOf(email), isEmpty);
  });

  testWidgets('«Ver todas» leads to «Mis reservas» @TP-01-H01-04', (
    tester,
  ) async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    final court = await createSpace(venue);
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    await occupy(court, tomorrow, 21, email: email);

    await signInAsUser(tester, email: email);
    await waitUntil(tester, find.text('VER TODAS →'));
    await tapText(tester, 'VER TODAS →');

    await waitUntil(tester, find.text('Mis reservas'));
    expect(find.text(court), findsOneWidget);
  });

  testWidgets(
    'the number of venues and courts in the hero comes from the loaded data @TP-01-H01-05',
    (tester) async {
      final email = 'socio.${unique()}@correo.com';
      await signInAsUser(tester, email: email);
      await waitUntil(
        tester,
        find.textContaining('disponibilidad en tiempo real'),
      );

      final venues = await venuesAUserSees();
      final total = venues.values.fold(0, (a, b) => a + b);

      // Verifies: the hero shows exactly what the API returns, not a fixed value.
      final howManyVenues = venues.length == 1 ? 'sede' : 'sedes';
      final howManyCourts = total == 1 ? 'cancha' : 'canchas';
      expect(
        find.text(
          '${venues.length} $howManyVenues · $total $howManyCourts'
          ' · disponibilidad en tiempo real',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    '«Buscar cancha» leads to «Consultar canchas» and «Ver sedes» to the venue listing'
    ' @TP-01-H01-06',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tapText(tester, 'Buscar cancha');
      await waitUntil(tester, find.text('Consultar canchas'));

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
      await tapText(tester, 'Ver sedes');
      await waitUntil(tester, find.text('Sedes'));
    },
  );

  testWidgets(
    'the bottom bar leads to Home, Venues, Bookings and Profile @TP-01-H01-07',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tapText(tester, 'SEDES');
      await waitUntil(tester, find.text('Sedes'));
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text('Mis reservas'));
      await tapText(tester, 'PERFIL');
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      await tapText(tester, 'INICIO');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
    },
  );

  testWidgets(
    'from the avatar card it reaches its profile and «Mis reservas» @TP-01-H01-08',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Perfil completo');
      await waitUntil(tester, find.text('DATOS PERSONALES'));
      await tapText(tester, 'INICIO');

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Mis reservas');
      await waitUntil(tester, find.text('Mis reservas'));
    },
  );

  testWidgets(
    'with no upcoming bookings, the Home does not show the next booking card'
    ' @TP-01-H02-01 @assumption:TP-01-SUP-01',
    (tester) async {
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      // Verifies: the Home finished loading and the next booking block is not there.
      await waitUntil(
        tester,
        find.textContaining('disponibilidad en tiempo real'),
      );
      expect(find.text('REINTENTAR'), findsNothing);
      expect(find.text('TU PRÓXIMA RESERVA'), findsNothing);
    },
  );

  testWidgets(
    'an administrator, on signing in, reaches the administration panel'
    ' @TP-01-H03-01',
    (tester) async {
      await signInAsAdmin(tester);

      // Verifies: it goes straight to the panel, not to the user Home.
      expect(find.text('PANEL ADMIN'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsNothing);
    },
  );
}
