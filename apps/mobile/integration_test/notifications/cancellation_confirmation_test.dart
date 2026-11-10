import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  final tomorrow = todayAtClub().add(const Duration(days: 1));
  const title = 'Reserva cancelada';

  String body(String venue, {String hour = '21:00'}) =>
      'Fútbol 5 · $venue · ${days[tomorrow.weekday - 1]} ${tomorrow.day}, $hour. '
      'El horario quedó liberado.';

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

  Future<void> closePanel(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel('Cerrar las notificaciones'));
    await tester.pumpAndSettle();
  }

  /// Cancels the booking of [court] tomorrow at [hour] from «Mis reservas», with the button of
  /// its card, and accepts the success message; the app stays on «Mis reservas», without that card.
  Future<void> cancelInApp(
    WidgetTester tester,
    String court, {
    int hour = 21,
  }) async {
    await tapText(tester, 'RESERVAS');
    await waitUntil(tester, find.text(court));
    final button = find.bySemanticsLabel(
      'Cancelar la reserva de Fútbol 5, '
      '${days[tomorrow.weekday - 1]} ${tomorrow.day}, $hour:00 – ${hour + 1}:00',
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await waitUntil(tester, find.text('¿Cancelar la reserva?'));
    await tapText(tester, 'CANCELAR RESERVA');
    await waitUntil(tester, find.text('Reserva cancelada con éxito'));
    await tapText(tester, 'ACEPTAR');
    final end = DateTime.now().add(const Duration(seconds: 20));
    while (find.text(court).evaluate().isNotEmpty &&
        DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(court), findsNothing);
  }

  bool highlighted(WidgetTester tester, String venue) => tester
      .getSemantics(
        find.bySemanticsLabel(RegExp('^Fútbol 5, ${RegExp.escape(venue)},')),
      )
      .flagsCollection
      .isSelected;

  testWidgets(
    'cancels a booking and receives the confirmation with the booking and the freed time @CU-24.3-H01-01 @assumption:CU-24.3-SUP-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, _) = await tomorrowBooking();
      await signIn(tester, email);

      // The cancellation arrives from another phone: here the person is on the Home.
      await cancelFromAnotherPhone(email);
      await waitUntil(tester, find.text(title));

      // Verifies: the top card says which booking was canceled and that the time was
      // freed, over the screen it was on.
      expect(find.text(body(venue)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'on tapping the confirmation the app opens the history with the canceled booking @CU-24.3-H01-02 @assumption:CU-24.3-SUP-06',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, court) = await tomorrowBooking();
      await signIn(tester, email);
      await cancelFromAnotherPhone(email);
      await waitUntil(tester, find.text(title));

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      // Verifies: «Mis reservas» on the history, with the booking as canceled and highlighted.
      await waitUntil(tester, find.text('CANCELADA'));
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(court), findsOneWidget);
      expect(highlighted(tester, venue), isTrue);
      expect(find.text('MARCAR TODAS'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the confirmation stays in the notification center @CU-24.3-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, _) = await tomorrowBooking();
      await signIn(tester, email);
      await cancelFromAnotherPhone(email);
      await waitUntil(tester, find.text(title));
      await closePanel(tester);

      await openCenter(tester, unread: 1);

      // Verifies: the confirmation is in the center, from today and unread.
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text(body(venue)), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'if it stays on «Mis reservas» it sees only the cancellation success message, without the card @CU-24.3-H02-01 @assumption:CU-24.3-SUP-03 @assumption:CU-24.3-SUP-07',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, court) = await tomorrowBooking();
      await anotherBooking(email, hour: 22);
      await signIn(tester, email);

      await cancelInApp(tester, court);

      // A reminder that arrives later makes the app read the center, which already has the
      // confirmation: the panel shows the reminder and not the confirmation.
      await dispatchReminders(email: email, day: tomorrow, hour: 21);
      await waitUntil(tester, find.text('Tu reserva es en 1 hora'));

      // Verifies: the confirmation card does not appear and the screen is still
      // «Mis reservas».
      expect(find.text(title), findsNothing);
      expect(find.text(body(venue)), findsNothing);
      expect(find.text('Mis reservas'), findsOneWidget);

      // Verifies: the confirmation is still unread on the bell and in the center.
      await closePanel(tester);
      await tapText(tester, 'INICIO');
      await openCenter(tester, unread: 2);
      expect(find.text(title), findsOneWidget);
      expect(find.text(body(venue)), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'without notification permission the push does not arrive but the confirmation is in the center @CU-24.3-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, venue, court) = await tomorrowBooking();
      await signIn(tester, email, permission: false);

      await cancelInApp(tester, court);
      await tapText(tester, 'INICIO');
      await openCenter(tester, unread: 1);

      // Verifies: the center says they are turned off and has the confirmation anyway.
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(find.text(body(venue)), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'if the cancellation failed it receives no confirmation @CU-24.3-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (email, _, court) = await tomorrowBooking();
      await signIn(tester, email);
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text(court));
      await tapText(tester, 'CANCELAR');
      await waitUntil(tester, find.text('¿Cancelar la reserva?'));

      // While it looks at the confirmation, the slot starts.
      await startBookingsOf(court);
      await tapText(tester, 'CANCELAR RESERVA');
      await waitUntil(tester, find.text('Esto cambió mientras tanto'));
      await tapText(tester, 'VER LO ACTUALIZADO');
      await tapText(tester, 'INICIO');

      // Verifies: the center stays empty and the bell counts nothing.
      await openCenter(tester);
      await waitUntil(tester, find.text('Todavía no tenés notificaciones'));
      expect(find.text(title), findsNothing);
      semantics.dispose();
    },
  );
}
