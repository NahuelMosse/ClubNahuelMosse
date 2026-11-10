import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tomorrow = todayAtClub().add(const Duration(days: 1));
  const title = 'Tu reserva es en 1 hora';

  Future<String> newAccount() async {
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    return email;
  }

  /// A new venue with a Fútbol 5 and a booking of [email] tomorrow at [hour].
  Future<(String, String)> tomorrowBooking(
    String email, {
    int hour = 21,
  }) async {
    final venue = 'Sede Morón ${unique()}';
    await createVenue(venue, 'Av. Rivadavia 19850');
    final court = await createSpace(venue);
    await occupy(court, tomorrow, hour, email: email);
    return (venue, court);
  }

  /// Signs in; [permission] is what the phone's system answers about
  /// notifications.
  Future<void> signIn(
    WidgetTester tester,
    String email, {
    bool permission = true,
    String? apiUrl,
  }) async {
    await openApp(tester, apiUrl: apiUrl);
    await setNotificationPermission(granted: permission);
    await typeInto(tester, 'Correo', email);
    await typeInto(tester, 'Contraseña', 'ClubNahuel1');
    await tapText(tester, 'INICIAR SESIÓN');
    await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
  }

  /// The API's reminder sweep running at [hour] tomorrow.
  Future<int> sweep(String email, int hour, {int minute = 0}) =>
      dispatchReminders(
        email: email,
        day: tomorrow,
        hour: hour,
        minute: minute,
      );

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

  /// The booking of [venue] in «Mis reservas», to check whether it is highlighted.
  Finder cardOf(String venue) =>
      find.bySemanticsLabel(RegExp('^Fútbol 5, ${RegExp.escape(venue)},'));

  bool highlighted(WidgetTester tester, String venue) =>
      tester.getSemantics(cardOf(venue)).flagsCollection.isSelected;

  testWidgets(
    'on tapping the reminder the app opens «Mis reservas» with that booking in view @CU-24.1-H01-02 @assumption:CU-24.1-SUP-03 @assumption:CU-24.1-SUP-11',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, court) = await tomorrowBooking(email);
      final (otherVenue, otherCourt) = await tomorrowBooking(email, hour: 22);
      await signIn(tester, email);
      await sweep(email, 20, minute: 30);
      await waitUntil(tester, find.text(title));

      await tester.tap(find.text(title));
      await tester.pumpAndSettle();

      // Verifies: it opens «Mis reservas», with both bookings and only the notified one highlighted.
      await waitUntil(tester, find.text(court));
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(otherCourt), findsOneWidget);
      expect(highlighted(tester, venue), isTrue);
      expect(highlighted(tester, otherVenue), isFalse);
      // Verifies: the panel closed and the tapped notice was marked as read.
      expect(find.text('MARCAR TODAS'), findsNothing);
      await tapText(tester, 'INICIO');
      await waitUntil(tester, bell(0));
      semantics.dispose();
    },
  );

  testWidgets(
    'the reminder stays in the notification center with sport, venue and time @CU-24.1-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, _) = await tomorrowBooking(email);
      await signIn(tester, email);
      await sweep(email, 20);
      await waitUntil(tester, find.text(title));
      await closePanel(tester);

      await openCenter(tester, unread: 1);

      // Verifies: the notice is in the center, grouped under HOY, with what the CU says.
      expect(find.text('HOY'), findsOneWidget);
      expect(find.text(title), findsOneWidget);
      expect(find.text('Fútbol 5 · $venue · 21:00 – 22:00'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'with the app open the reminder appears as a top card without changing screen @CU-24.1-H02-01 @assumption:CU-24.1-SUP-09',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, court) = await tomorrowBooking(email);
      await signIn(tester, email);
      await tapText(tester, 'RESERVAS');
      await waitUntil(tester, find.text(court));

      await sweep(email, 20);
      await waitUntil(tester, find.text(title));

      // Verifies: the card has the full notice and the screen below is still
      // «Mis reservas».
      expect(find.text('Fútbol 5 · $venue · 21:00 – 22:00'), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsOneWidget);
      expect(find.text('Mis reservas'), findsOneWidget);
      await closePanel(tester);
      expect(find.text(title), findsNothing);
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text(court), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'without notification permission the center shows «Notificaciones desactivadas» and the notice is recorded @CU-24.1-H03-01 @assumption:CU-24.1-SUP-08',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, _) = await tomorrowBooking(email);
      await signIn(tester, email, permission: false);

      await sweep(email, 20);
      await openCenter(tester, unread: 1);

      // Verifies: the center says they are turned off and offers to turn them on, the app did not
      // open the panel on top, and the API knows this device has no permission.
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(
        find.text(
          'Activá los avisos para que te recordemos tus reservas una hora antes.',
        ),
        findsOneWidget,
      );
      expect(find.text('ACTIVAR NOTIFICACIONES'), findsOneWidget);
      expect(find.text('MARCAR TODAS'), findsNothing);
      expect(await devicesOf(email), [false]);
      // Verifies: the reminder stayed in the center anyway.
      expect(find.text('Fútbol 5 · $venue · 21:00 – 22:00'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'from «Notificaciones desactivadas» it turns on the notices and starts receiving them @CU-24.1-H03-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, _) = await tomorrowBooking(email);
      await signIn(tester, email, permission: false);
      await openCenter(tester);
      expect(find.text('Notificaciones desactivadas'), findsOneWidget);
      expect(await devicesOf(email), [false]);

      await tapText(tester, 'ACTIVAR NOTIFICACIONES');

      // Verifies: the center stops saying they are turned off and the API registers the
      // device with permission.
      await waitUntil(tester, find.text('Todavía no tenés notificaciones'));
      expect(find.text('Notificaciones desactivadas'), findsNothing);
      expect(await devicesOf(email), [true]);
      // Verifies: the next reminder reaches the open app.
      await sweep(email, 20);
      await waitUntil(tester, find.text('Fútbol 5 · $venue · 21:00 – 22:00'));
      semantics.dispose();
    },
  );

  testWidgets(
    'a reminder that was not tapped stays unread, also after opening the center @CU-24.1-H04-01 @assumption:CU-24.1-SUP-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, _) = await tomorrowBooking(email);
      await signIn(tester, email);
      await sweep(email, 20);
      await waitUntil(tester, find.text(title));
      await closePanel(tester);

      await openCenter(tester, unread: 1);

      // Verifies: the notice appears as unread; looking at the center does not mark it.
      expect(
        find.bySemanticsLabel(
          RegExp('^$title.*Fútbol 5 · ${RegExp.escape(venue)}.*sin leer'),
        ),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await waitUntil(tester, bell(1));
      semantics.dispose();
    },
  );

  testWidgets(
    '«Marcar todas» leaves all the notifications as read and stays that way on reopening the app @CU-24.1-H04-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (venue, _) = await tomorrowBooking(email);
      final (otherVenue, _) = await tomorrowBooking(email);
      await signIn(tester, email);
      expect(await sweep(email, 20), 2);
      await waitUntil(tester, find.text('MARCAR TODAS'));

      await tester.tap(find.text('MARCAR TODAS'));
      await tester.pumpAndSettle();

      // Verifies: the panel closes and the bell no longer counts any unread.
      expect(find.text('MARCAR TODAS'), findsNothing);
      await waitUntil(tester, bell(0));
      // Verifies: in the center both are read.
      await openCenter(tester);
      expect(find.bySemanticsLabel(RegExp('sin leer')), findsNothing);
      expect(find.textContaining(venue), findsOneWidget);
      expect(find.textContaining(otherVenue), findsOneWidget);
      // Verifies: it persisted; on reopening the app they are still read.
      await reopenApp(tester);
      await waitUntil(tester, bell(0));
      semantics.dispose();
    },
  );

  testWidgets(
    'with no notifications the center says there are none yet @no-sentinel:empty state @assumption:CU-24.1-SUP-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      await signIn(tester, email);

      await openCenter(tester);

      // Verifies: the empty state with its caption, not a blank screen.
      expect(find.text('Todavía no tenés notificaciones'), findsOneWidget);
      expect(
        find.text('Acá vas a ver los recordatorios de tus reservas.'),
        findsOneWidget,
      );
      expect(find.text('Notificaciones desactivadas'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the center sorts from the newest to the oldest @assumption:CU-24.1-SUP-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final (first, _) = await tomorrowBooking(email);
      final (second, _) = await tomorrowBooking(email, hour: 22);
      await signIn(tester, email);
      await sweep(email, 20, minute: 30);
      await waitUntil(tester, find.text(title));
      await closePanel(tester);
      await sweep(email, 21, minute: 30);
      await waitUntil(tester, bell(2));

      await openCenter(tester, unread: 2);

      // Verifies: the 22 notice (the last to arrive) is above the 21 one.
      final at21 = find.text('Fútbol 5 · $first · 21:00 – 22:00');
      final at22 = find.text('Fútbol 5 · $second · 22:00 – 23:00');
      expect(at21, findsOneWidget);
      expect(at22, findsOneWidget);
      expect(tester.getTopLeft(at22).dy < tester.getTopLeft(at21).dy, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'on signing out the device stops receiving notices @assumption:CU-24.1-SUP-08',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      await signIn(tester, email);
      expect(await devicesOf(email), [true]);

      await tester.tap(find.bySemanticsLabel('Tu cuenta'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Cerrar sesión');

      // Verifies: the API no longer has any active device for that account (decision 14).
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);
      expect(await devicesOf(email), isEmpty);
      semantics.dispose();
    },
  );

  testWidgets(
    'offline, opening the center warns of the error and offers to retry @no-sentinel:network error',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final email = await newAccount();
      final api = await ProxyApi.open();
      await signIn(tester, email, apiUrl: api.url);
      await waitUntil(tester, bell(0));

      api.state = ApiState.offline;
      await tester.tap(bell(0));
      await tester.pumpAndSettle();

      // Verifies: the network notice with retry, not an empty center that misleads.
      await waitUntil(tester, find.text('Error de conexión'));
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text('Todavía no tenés notificaciones'), findsNothing);
      semantics.dispose();
    },
  );
}
