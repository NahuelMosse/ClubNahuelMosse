import 'dart:ui' show SemanticsFlags, Tristate;

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

  String chip(DateTime day) => '${days[day.weekday - 1]} ${day.day}';

  String slot(int hour, [int hours = 1]) {
    String two(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
    return '${two(hour)} – ${two(hour + hours)}';
  }

  /// A venue open 08:00 to 23:00 with a covered Fútbol 5 court at $ 43.000 an hour.
  Future<(String, String)> venueWithCourt() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    return (venue, await createSpace(venue));
  }

  Future<String> account() async {
    final email = 'socio.${unique()}@correo.com';
    await createAccount(email: email, password: 'ClubNahuel1');
    return email;
  }

  Future<void> signIn(
    WidgetTester tester,
    String email, {
    String password = 'ClubNahuel1',
    String? apiUrl,
  }) async {
    await openApp(tester, apiUrl: apiUrl);
    await typeInto(tester, 'Correo', email);
    await typeInto(tester, 'Contraseña', password);
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

  /// From the venue to the times of its court, tomorrow, with [hours] hours.
  Future<void> openTimes(
    WidgetTester tester,
    String venue, {
    int hours = 1,
  }) async {
    await tapText(tester, 'SEDES');
    final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(venue)},'));
    await waitUntil(tester, card);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tapText(tester, 'VER HORARIOS / RESERVAR');
    await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
    await tapLabel(tester, chip(tomorrow));
    for (var i = 1; i < hours; i++) {
      await tapLabel(tester, 'Una hora más');
    }
  }

  /// Picks the slot that starts at [hour] and reaches «Confirmá tu reserva».
  Future<void> goToConfirm(
    WidgetTester tester,
    String venue, {
    int hour = 18,
    int hours = 1,
  }) async {
    await openTimes(tester, venue, hours: hours);
    await tapLabel(tester, slot(hour, hours));
    await tapText(tester, 'CONTINUAR');
    await waitUntil(tester, find.text('Confirmá tu reserva'));
  }

  testWidgets(
    'confirms the booking and it shows as active in «Mis reservas» with venue, space, date, time and total @CU-09-H01-01',
    (tester) async {
      final (venue, court) = await venueWithCourt();
      final email = await account();
      await signIn(tester, email);
      await goToConfirm(tester, venue);

      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifies: the receipt with the space and the time.
      await waitUntil(tester, find.text('¡Reserva confirmada!'));
      expect(find.text(court), findsOneWidget);
      expect(find.textContaining(slot(18)), findsOneWidget);

      await tapText(tester, 'VER MIS RESERVAS');

      // Verifies: in «Mis reservas», active and with all its data.
      await waitUntil(tester, find.text(court));
      expect(find.text('$venue · Av. Vergara 1850'), findsOneWidget);
      expect(find.text(slot(18)), findsOneWidget);
      expect(find.textContaining('43.000'), findsOneWidget);
      expect(find.text('ACTIVA'), findsOneWidget);
    },
  );

  testWidgets(
    'after booking, that time shows as unavailable to another user @CU-09-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _) = await venueWithCourt();
      await signIn(tester, await account());
      await goToConfirm(tester, venue, hour: 11);
      await tapText(tester, 'CONFIRMAR RESERVA');
      await waitUntil(tester, find.text('¡Reserva confirmada!'));

      // Another person opens the times of the same court.
      await signIn(tester, await account());
      await openTimes(tester, venue);

      // Verifies: 11 can no longer be picked.
      expect(flags(tester, slot(11)).isEnabled == Tristate.isTrue, isFalse);
      expect(flags(tester, slot(12)).isEnabled == Tristate.isTrue, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'books several consecutive hours and the total is the hourly price times the duration @CU-09-H01-03',
    (tester) async {
      final (venue, _) = await venueWithCourt();
      final email = await account();
      await signIn(tester, email);
      await goToConfirm(tester, venue, hour: 15, hours: 3);
      expect(find.text('${slot(15, 3)} · 3 horas'), findsOneWidget);

      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifies: three hours at $ 43.000.
      await waitUntil(tester, find.text('¡Reserva confirmada!'));
      expect(find.textContaining('129.000'), findsOneWidget);
      expect(await bookingsOf(email), hasLength(1));
    },
  );

  testWidgets(
    'taps «Cancelar» on the confirmation and no booking is created @CU-09-H01-07',
    (tester) async {
      final (venue, _) = await venueWithCourt();
      final email = await account();
      await signIn(tester, email);
      await goToConfirm(tester, venue);

      await tapText(tester, 'CANCELAR');

      // Verifies: back to the times and there is no booking.
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(await bookingsOf(email), isEmpty);
    },
  );

  testWidgets(
    'from the receipt goes to «Mis reservas» or back to the home screen @CU-09-H01-09',
    (tester) async {
      final (venue, _) = await venueWithCourt();
      await signIn(tester, await account());
      await goToConfirm(tester, venue);
      await tapText(tester, 'CONFIRMAR RESERVA');
      await waitUntil(tester, find.text('¡Reserva confirmada!'));

      // Verifies: both exits are there.
      expect(find.text('VER MIS RESERVAS'), findsOneWidget);
      await tapText(tester, 'Volver al inicio');
      await waitUntil(tester, find.text('RESERVÁ TU CANCHA'));
    },
  );

  testWidgets(
    'another person booked that time while confirming: sees the notice and no booking is created @CU-09-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court) = await venueWithCourt();
      final email = await account();
      await signIn(tester, email);
      await goToConfirm(tester, venue, hour: 20);

      // While confirming, another person takes that time.
      await occupy(court, tomorrow, 20);
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifies: the notice, and back on the grid the time is taken.
      await waitUntil(tester, find.text('Ese horario se ocupó'));
      await tapText(tester, 'ELEGIR OTRO HORARIO');
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(flags(tester, slot(20)).isEnabled == Tristate.isTrue, isFalse);
      expect(await bookingsOf(email), isEmpty);
      semantics.dispose();
    },
  );

  testWidgets(
    'with no time picked, the confirm button is disabled @CU-09-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _) = await venueWithCourt();
      await signIn(tester, await account());

      await openTimes(tester, venue);

      // Verifies: cannot continue until one is picked, and the summary says what is missing.
      expect(find.text('Sin horario elegido'), findsOneWidget);
      expect(flags(tester, 'CONTINUAR').isEnabled == Tristate.isTrue, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'with an expired session goes to login and, on signing in again, resumes the booking in progress @CU-09-H04-01',
    (tester) async {
      final (venue, court) = await venueWithCourt();
      final email = await account();
      await signIn(tester, email);
      await goToConfirm(tester, venue, hour: 16);

      // The password changes from another phone and the session expires.
      await changeFromAnotherDevice(email, 'ClubNahuel1', 'ClubNahuel2');
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifies: warns and leads to the sign-in screen.
      await waitUntil(tester, find.text('Tu sesión expiró'));
      await tapText(tester, 'IR AL INICIO DE SESIÓN');
      await waitUntil(tester, find.text('INICIAR SESIÓN'));
      await typeInto(tester, 'Correo', email);
      await typeInto(tester, 'Contraseña', 'ClubNahuel2');
      await tapText(tester, 'INICIAR SESIÓN');

      // Verifies: back on the confirmation with the same court and the same time.
      await waitUntil(tester, find.text('Confirmá tu reserva'));
      expect(find.text('${slot(16)} · 1 hora'), findsOneWidget);
      await tapText(tester, 'CONFIRMAR RESERVA');
      await waitUntil(tester, find.text('¡Reserva confirmada!'));
      expect(await bookingsOf(email, password: 'ClubNahuel2'), [
        (court, '16:00'),
      ]);
    },
  );

  testWidgets(
    'with no connection on confirming, sees the error and the booking is not created @CU-09-H05-01',
    (tester) async {
      final (venue, _) = await venueWithCourt();
      final email = await account();
      final api = await ProxyApi.open();
      await signIn(tester, email, apiUrl: api.url);
      await goToConfirm(tester, venue);

      api.state = ApiState.offline;
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifies: the connection notice, stays on the confirmation and there is no booking.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('Confirmá tu reserva'), findsOneWidget);
      expect(await bookingsOf(email), isEmpty);
    },
  );

  testWidgets(
    'the server fails on confirming and the booking is not created @CU-09-H05-02',
    (tester) async {
      final (venue, _) = await venueWithCourt();
      final email = await account();
      final api = await ProxyApi.open();
      await signIn(tester, email, apiUrl: api.url);
      await goToConfirm(tester, venue);

      api.state = ApiState.failing;
      await tapText(tester, 'CONFIRMAR RESERVA');

      // Verifies: the server error, stays on the confirmation and there is no booking.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('Confirmá tu reserva'), findsOneWidget);
      expect(await bookingsOf(email), isEmpty);
    },
  );
}
