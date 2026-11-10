import 'dart:ui' show SemanticsFlags;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const weekdayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// The label of the chip of [day] in FECHA: «Viernes 13».
  String chip(DateTime day) => '${weekdayNames[day.weekday - 1]} ${day.day}';

  /// The slot that starts at [hour] sharp and lasts [hours]: «18:00 – 19:00».
  String slot(int hour, [int hours = 1]) {
    String two(int h) => '${(h % 24).toString().padLeft(2, '0')}:00';
    return '${two(hour)} – ${two(hour + hours)}';
  }

  final tomorrow = todayAtClub().add(const Duration(days: 1));
  final dayAfter = todayAtClub().add(const Duration(days: 2));

  /// A venue open 08:00 to 23:00 with two covered Fútbol 5 courts at $ 43.000 an hour.
  Future<(String, String, String)> venueWithTwoCourts({
    List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  }) async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850', days: days);
    return (venue, await createSpace(venue), await createSpace(venue));
  }

  /// Signs in as a user and opens the times of «Cancha 1» of [venue].
  Future<void> openTimes(
    WidgetTester tester,
    String venue, {
    String? apiUrl,
    void Function()? beforeSignIn,
  }) async {
    await signInAsUser(
      tester,
      email: 'socio.${unique()}@correo.com',
      apiUrl: apiUrl,
    );
    await tapText(tester, 'SEDES');
    final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(venue)},'));
    await waitUntil(tester, card);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    final book = find.text('VER HORARIOS / RESERVAR');
    await waitUntil(tester, book);
    beforeSignIn?.call();
    await tester.ensureVisible(book.first);
    await tester.pumpAndSettle();
    await tester.tap(book.first);
    await tester.pumpAndSettle();
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

  bool enabled(WidgetTester tester, String label) =>
      flags(tester, label).isEnabled;

  bool selected(WidgetTester tester, String label) =>
      flags(tester, label).isSelected;

  Future<void> viewDay(WidgetTester tester, DateTime day) async {
    await tapLabel(tester, chip(day));
    await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
  }

  testWidgets(
    'opens the times with court, today\'s date and 1 hour by default, and can only pick free, future slots @CU-12-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _) = await venueWithTwoCourts();
      await openTimes(tester, venue);

      // Verifies: «Cancha 1», today and 1 hour come picked.
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(selected(tester, 'Cancha 1, Techada'), isTrue);
      expect(selected(tester, chip(todayAtClub())), isTrue);
      expect(find.text('1 hora'), findsOneWidget);

      // Verifies: hours that already started are not offered and the next one is.
      final now = hourAtClub();
      for (var h = 8; h <= now && h <= 22; h++) {
        expect(find.bySemanticsLabel(slot(h)), findsNothing);
      }
      final next = now < 8 ? 8 : now + 1;
      if (next <= 22) {
        expect(enabled(tester, slot(next)), isTrue);
      } else {
        expect(find.text('No hay horarios disponibles'), findsOneWidget);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'a slot that another person already booked shows as unavailable @CU-12-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court1, _) = await venueWithTwoCourts();
      await occupy(court1, tomorrow, 10);
      await openTimes(tester, venue);

      await viewDay(tester, tomorrow);

      // Verifies: the 10 one is shown but cannot be picked; the next one can.
      expect(enabled(tester, slot(10)), isFalse);
      expect(enabled(tester, slot(11)), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'picks a slot and the summary shows the time and the total; continue leads to booking @CU-12-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _) = await venueWithTwoCourts();
      await openTimes(tester, venue);
      await viewDay(tester, tomorrow);

      await tapLabel(tester, slot(18));

      // Verifies: the slot is picked and the summary shows time, date and total.
      expect(selected(tester, slot(18)), isTrue);
      expect(find.text(slot(18)), findsNWidgets(2));
      expect(find.textContaining('43.000 × 1'), findsOneWidget);
      expect(find.textContaining(_month(tomorrow)), findsOneWidget);

      await tapText(tester, 'CONTINUAR');

      // Verifies: the confirmation receives the venue, the court, the date and the time.
      await waitUntil(tester, find.text('Confirmá tu reserva'));
      expect(find.text(venue.toUpperCase()), findsOneWidget);
      expect(find.text('Cancha 1 · Techada'), findsOneWidget);
      expect(find.text('${slot(18)} · 1 hora'), findsOneWidget);
      expect(find.textContaining('43.000'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the continue button is disabled while no slot is picked @CU-12-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _) = await venueWithTwoCourts();
      await openTimes(tester, venue);

      await viewDay(tester, tomorrow);

      // Verifies: with no slot there is no time in the summary and it cannot continue.
      expect(find.text('Sin horario elegido'), findsOneWidget);
      expect(enabled(tester, 'CONTINUAR'), isFalse);
      await tester.tap(find.text('CONTINUAR'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmá tu reserva'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the grid note says how many times are unavailable @CU-12-H01-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court1, _) = await venueWithTwoCourts();
      await occupy(court1, tomorrow, 9);
      await occupy(court1, tomorrow, 12);
      await openTimes(tester, venue);

      await viewDay(tester, tomorrow);

      // Verifies: two taken, two unavailable.
      await waitUntil(
        tester,
        find.text('Algunos horarios ya están ocupados · 2 no disponibles'),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'changes the date and the grid is recalculated for that day @CU-12-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court1, _) = await venueWithTwoCourts();
      await occupy(court1, tomorrow, 10);
      await openTimes(tester, venue);
      await viewDay(tester, tomorrow);
      expect(enabled(tester, slot(10)), isFalse);

      await viewDay(tester, dayAfter);

      // Verifies: the other day the 10 one is free.
      expect(selected(tester, chip(dayAfter)), isTrue);
      expect(enabled(tester, slot(10)), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'changes the court and the grid is recalculated for that court @CU-12-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, court2) = await venueWithTwoCourts();
      await occupy(court2, tomorrow, 10);
      await openTimes(tester, venue);
      await viewDay(tester, tomorrow);
      expect(enabled(tester, slot(10)), isTrue);

      await tapLabel(tester, 'Cancha 2, Techada');

      // Verifies: on «Cancha 2» the 10 one is taken.
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(selected(tester, 'Cancha 2, Techada'), isTrue);
      expect(enabled(tester, slot(10)), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'with 2 hours only starts with both hours free and ending before closing are offered @CU-12-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court1, _) = await venueWithTwoCourts();
      await occupy(court1, tomorrow, 11);
      await openTimes(tester, venue);
      await viewDay(tester, tomorrow);

      await tapLabel(tester, 'Una hora más');

      // Verifies: those that overlap 11 cannot be picked, the rest can.
      await waitUntil(tester, find.text('2 horas'));
      expect(enabled(tester, slot(9, 2)), isTrue);
      expect(enabled(tester, slot(10, 2)), isFalse);
      expect(enabled(tester, slot(11, 2)), isFalse);
      expect(enabled(tester, slot(12, 2)), isTrue);

      // Verifies: the last one ends at closing.
      expect(enabled(tester, slot(21, 2)), isTrue);
      expect(find.bySemanticsLabel(slot(22, 2)), findsNothing);
      expect(
        find.text('Con 2 horas hay menos inicios posibles · 2 no disponibles'),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'with more hours the same rule holds and the total is hourly price times duration @CU-12-H04-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court1, _) = await venueWithTwoCourts();
      await occupy(court1, tomorrow, 15);
      await openTimes(tester, venue);
      await viewDay(tester, tomorrow);
      await tapLabel(tester, 'Una hora más');
      await tapLabel(tester, 'Una hora más');
      await waitUntil(tester, find.text('3 horas'));

      await tapLabel(tester, slot(18, 3));

      // Verifies: with 3 hours the one overlapping 15 is not offered, and the total is for three.
      expect(enabled(tester, slot(13, 3)), isFalse);
      expect(enabled(tester, slot(20, 3)), isTrue);
      expect(find.bySemanticsLabel(slot(21, 3)), findsNothing);
      expect(find.textContaining('43.000 × 3'), findsOneWidget);
      expect(find.textContaining('129.000'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the duration goes from 1 to 4 hours: at 1 hour it cannot go down and at 4 it cannot go up @CU-12-H04-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _) = await venueWithTwoCourts();
      await openTimes(tester, venue);
      await viewDay(tester, tomorrow);

      // Verifies: starts at 1 hour unable to go down, with the rule in view.
      expect(enabled(tester, 'Una hora menos'), isFalse);
      expect(
        find.text('Horas completas, de 1 a 4 h. La sede cierra a las 23:00.'),
        findsOneWidget,
      );

      for (var i = 0; i < 3; i++) {
        await tapLabel(tester, 'Una hora más');
      }

      // Verifies: at 4 hours it does not go up any more.
      await waitUntil(tester, find.text('4 horas'));
      expect(enabled(tester, 'Una hora más'), isFalse);
      expect(enabled(tester, 'Una hora menos'), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'no free slot is left and sees the empty state with the suggestion @CU-12-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, court1, _) = await venueWithTwoCourts();
      await occupy(court1, tomorrow, 8, hours: 4);
      await occupy(court1, tomorrow, 12, hours: 4);
      await occupy(court1, tomorrow, 16, hours: 4);
      await occupy(court1, tomorrow, 20, hours: 3);
      await openTimes(tester, venue);

      await viewDay(tester, tomorrow);

      // Verifies: the empty state replaces the grid and suggests another date.
      await waitUntil(tester, find.text('No hay horarios disponibles'));
      expect(
        find.text(
          'Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(slot(8)), findsNothing);
      expect(enabled(tester, 'CONTINUAR'), isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'picks a day the venue is closed and sees the empty state @CU-12-H05-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _) = await venueWithTwoCourts(
        days: [
          for (var d = 1; d <= 7; d++)
            if (d != tomorrow.weekday) d,
        ],
      );
      await openTimes(tester, venue);

      await viewDay(tester, tomorrow);

      // Verifies: the venue is closed that day and there are no slots.
      await waitUntil(tester, find.text('No hay horarios disponibles'));
      expect(
        find.text('La sede no abre ese día. Probá con otra fecha.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(slot(10)), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets('with no connection, sees the alert and no times @CU-12-H06-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (venue, _, _) = await venueWithTwoCourts();
    final api = await ProxyApi.open();

    await openTimes(
      tester,
      venue,
      apiUrl: api.url,
      beforeSignIn: () => api.state = ApiState.offline,
    );

    // Verifies: the connection alert and, once closed, no times.
    await waitUntil(tester, find.text('Error de conexión'));
    await tapText(tester, 'Volver');
    expect(find.text('HORARIO DISPONIBLE'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^\d\d:00 – ')), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the server fails and no times are shown @CU-12-H07-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (venue, _, _) = await venueWithTwoCourts();
    final api = await ProxyApi.open();

    await openTimes(
      tester,
      venue,
      apiUrl: api.url,
      beforeSignIn: () => api.state = ApiState.failing,
    );

    // Verifies: the server error and, once closed, no times.
    await waitUntil(tester, find.text('Error del servidor'));
    await tapText(tester, 'ACEPTAR');
    expect(find.text('HORARIO DISPONIBLE'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^\d\d:00 – ')), findsNothing);
    expect(find.text('REINTENTAR'), findsOneWidget);
    semantics.dispose();
  });
}

const _months = [
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

String _month(DateTime day) => '${day.day} de ${_months[day.month - 1]}';
