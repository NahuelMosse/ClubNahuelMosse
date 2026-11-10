import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final tomorrow = todayAtClub().add(const Duration(days: 1));
  const title = 'El club anuló tu reserva';
  const reason = 'mantenimiento de la cancha';

  String body(String venue, {String hour = '21:00'}) =>
      'Fútbol 5 · $venue · ${days[tomorrow.weekday - 1]} ${tomorrow.day}, $hour. '
      'Motivo: $reason.';

  /// A new venue with a Fútbol 5 and a booking of [email] tomorrow at [hour].
  Future<(String, String)> anotherBooking(String email, {int hour = 21}) async {
    final venue = 'Sede Morón ${unique()}';
    await createVenue(venue, 'Av. Rivadavia 19850');
    final court = await createSpace(venue);
    await occupy(court, tomorrow, hour, email: email);
    return (venue, court);
  }

  /// A new account with a booking tomorrow at 21.
  Future<(String, String, String)> tomorrowBooking() async {
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    final (venue, court) = await anotherBooking(email);
    return (email, venue, court);
  }

  Future<void> signIn(
    WidgetTester tester,
    String email, {
    bool permission = true,
  }) async {
    await openApp(tester);
    await setNotificationPermission(granted: permission);
    await typeInto(tester, 'Correo', email);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

  Finder bell(int unread) => find.bySemanticsLabel(
    unread == 0 ? 'Notificaciones' : 'Notificaciones, $unread sin leer',
  );

  Future<void> openCenter(WidgetTester tester, {int unread = 0}) async {
    await waitUntil(tester, bell(unread));
    await tester.tap(bell(unread));
    await tester.pumpAndSettle();
    await waitUntil(tester, find.text('Notificaciones'));
  }

  bool highlighted(WidgetTester tester, String venue) => tester
      .getSemantics(
        find.bySemanticsLabel(RegExp('^Fútbol 5, ${RegExp.escape(venue)},')),
      )
      .flagsCollection
      .isSelected;

  testWidgets(
    'the administrator voids the booking and the user sees the notice with sport, venue, date and reason @CU-24.2-H01-01 @assumption:CU-24.2-SUP-06',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, _) = await tomorrowBooking();
      await signIn(tester, email);

      // The voiding comes from the club: here the person is on the Home.
      final [booking] = await upcomingOf(email);
      expect(await voidFromAdmin(booking), 200);
      await waitUntil(tester, find.text(title));

      // Verifies: the top card has the booking and the reason, over the screen it
      // was on.
      expect(find.text(body(venue)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'on tapping the notice the app opens the history with the voided booking and its reason @CU-24.2-H01-02 @assumption:CU-24.2-SUP-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, court) = await tomorrowBooking();
      await signIn(tester, email);
      final [booking] = await upcomingOf(email);
      expect(await voidFromAdmin(booking), 200);
      await waitUntil(tester, find.text(title));

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      // Verifies: «Mis reservas» on the history, with the voided booking, its reason and highlighted.
      await waitUntil(tester, find.text('ANULADA'));
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(court), findsOneWidget);
      expect(
        find.text('Anulada por el administrador · $reason'),
        findsOneWidget,
      );
      expect(highlighted(tester, venue), isTrue);
      expect(find.text('MARCAR TODAS'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the notice delivery is recorded in the traceability of the booking the administrator sees @CU-24.2-H01-03 @assumption:CU-24.2-SUP-07',
    (tester) async {
      final (email, venue, court) = await tomorrowBooking();
      final [booking] = await upcomingOf(email);
      expect(await voidFromAdmin(booking), 200);
      // The run has no notification service: the notice stays in the center.
      expect(await waitForNoticeDelivery(court), 'sin_canal');

      await signInAsAdmin(tester);
      await typeInto(tester, 'Buscar reserva', venue);
      await waitUntil(tester, find.text(court));
      await tapText(tester, court);

      // Verifies: the detail leaves the notice in the traceability, along with the voiding.
      await waitUntil(tester, find.text('Detalle de reserva'));
      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('Aviso en el centro del usuario'), findsOneWidget);
      expect(find.text('El push no salió'), findsOneWidget);
    },
  );

  testWidgets(
    'several bookings voided for the same person arrive in a single notice with the count @CU-24.2-H03-01 @assumption:CU-24.2-SUP-02 @assumption:CU-24.2-SUP-06',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, _, _) = await tomorrowBooking();
      await anotherBooking(email, hour: 22);
      await signIn(tester, email, permission: false);

      for (final booking in await upcomingOf(email)) {
        expect(await voidFromAdmin(booking), 200);
      }
      await openCenter(tester, unread: 1);

      // Verifies: a single notice, which says how many there are; tapping it leads to the history.
      expect(find.text('El club anuló 2 de tus reservas'), findsOneWidget);
      expect(
        find.text(
          'Tenés 2 reservas anuladas por el club. Mirá el detalle en tu historial.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('El club anuló 2 de tus reservas'));
      await tester.pumpAndSettle();
      await waitUntil(tester, find.text('Mis reservas'));
      expect(find.text('ANULADA'), findsNWidgets(2));
      semantics.dispose();
    },
  );

  testWidgets(
    'without notification permission the push does not arrive but the notice is in the center @CU-24.2-H04-01 @assumption:CU-24.2-SUP-07',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, court) = await tomorrowBooking();
      await signIn(tester, email, permission: false);

      final [booking] = await upcomingOf(email);
      expect(await voidFromAdmin(booking), 200);
      await openCenter(tester, unread: 1);

      // Verifies: the center says they are turned off and has the voiding anyway; the API
      // knows the push did not go out.
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text(body(venue)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(await waitForNoticeDelivery(court), 'sin_permiso');
      semantics.dispose();
    },
  );

  testWidgets(
    'if the user had already canceled the booking it does not receive the club notice @CU-24.2-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, court) = await tomorrowBooking();
      final [booking] = await upcomingOf(email);
      // Without permission the panel does not open by itself on the Home and the bell opens the center.
      await signIn(tester, email, permission: false);
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text(court));
      await tapText(tester, 'CANCELAR');
      await waitUntil(tester, find.text('¿Cancelar la reserva?'));
      await tapText(tester, 'CANCELAR RESERVA');
      await waitUntil(tester, find.text('Reserva cancelada con éxito'));
      await tapText(tester, 'ACEPTAR');
      await tapText(tester, 'INICIO');

      // The club tries to void it afterwards: the booking is no longer active.
      expect(await voidFromAdmin(booking), 409);
      await openCenter(tester, unread: 1);

      // Verifies: the center only has the confirmation of its own cancellation.
      expect(find.text('Reserva cancelada'), findsOneWidget);
      expect(find.text(title), findsNothing);
      expect(find.text(body(venue)), findsNothing);
      semantics.dispose();
    },
  );
}
