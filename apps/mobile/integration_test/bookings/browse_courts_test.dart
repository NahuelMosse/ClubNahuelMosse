import 'dart:ui' show SemanticsFlags, Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tomorrow = todayAtClub().add(const Duration(days: 1));
  final yesterday = todayAtClub().subtract(const Duration(days: 1));

  /// «29 / 09 / 2026», as the field shows it.
  String date(DateTime day) =>
      '${day.day.toString().padLeft(2, '0')} / '
      '${day.month.toString().padLeft(2, '0')} / ${day.year}';

  const days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  /// A venue open 08:00 to 23:00 with two «Fútbol 5» and one «Fútbol 7».
  Future<(String, String, String, String)> venueWithCourts() async {
    final venue = 'Sede Haedo ${unique()}';
    await createVenue(venue, 'Av. Vergara 1850');
    return (
      venue,
      await createSpace(venue),
      await createSpace(venue),
      await createSpace(venue, kind: 'F7'),
    );
  }

  Future<void> openSearch(WidgetTester tester, {String? apiUrl}) async {
    await signInAsUser(
      tester,
      email: 'socio.${unique()}@correo.com',
      apiUrl: apiUrl,
    );
    await tapText(tester, 'Buscar cancha');
    await waitUntil(tester, find.text('Consultar canchas'));
  }

  Future<void> fillIn(
    WidgetTester tester,
    String venue, {
    String kind = 'Fútbol 5',
    DateTime? day,
    String from = '10:00',
    String to = '12:00',
  }) async {
    await choose(tester, 'Sede', venue);
    await choose(tester, 'Deporte', 'Fútbol');
    await choose(tester, 'Tipo de cancha', kind);
    await typeInto(tester, 'Fecha', date(day ?? tomorrow));
    await choose(tester, 'Desde', from);
    await choose(tester, 'Hasta', to);
  }

  SemanticsFlags flags(WidgetTester tester, String label) =>
      tester.getSemantics(find.bySemanticsLabel(label)).flagsCollection;

  testWidgets(
    'queries venue, type, date and range and sees only the courts free across that whole range @CU-13-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, f5a, f5b, f7) = await venueWithCourts();
      await occupy(f5b, tomorrow, 11);
      await openSearch(tester);
      await fillIn(tester, venue);

      await tapText(tester, 'CONSULTAR');

      // Verifies: only the Fútbol 5 free from 10 to 12, with the queried range.
      await waitUntil(
        tester,
        find.text('1 CANCHA DISPONIBLE · FÚTBOL 5 · 10:00 – 12:00'),
      );
      expect(find.text(f5a), findsOneWidget);
      expect(find.text(f5b), findsNothing);
      expect(find.text(f7), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'a court with a booking that overlaps the range does not show as available @CU-13-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, f5a, f5b, _) = await venueWithCourts();
      // The one on «Cancha 1» ends when the range starts; the one on «Cancha 2» overlaps it.
      await occupy(f5a, tomorrow, 9);
      await occupy(f5b, tomorrow, 11, hours: 2);
      await openSearch(tester);
      await fillIn(tester, venue);

      await tapText(tester, 'CONSULTAR');

      // Verifies: the one ending at 10 is free; the one overlapping the range is not.
      await waitUntil(tester, find.text(f5a));
      expect(find.text(f5b), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'picks a court from the result and moves on to book it with the queried time @CU-13-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, f5a, f5b, _) = await venueWithCourts();
      // With «Cancha 2» taken, the result brings a single court to pick.
      await occupy(f5b, tomorrow, 11);
      await openSearch(tester);
      await fillIn(tester, venue);
      await tapText(tester, 'CONSULTAR');
      await waitUntil(tester, find.text(f5a));

      await tapText(tester, 'VER HORARIOS / RESERVAR');

      // Verifies: the grid of that court arrives with the day, the duration and the time.
      await waitUntil(tester, find.text('HORARIO DISPONIBLE'));
      expect(flags(tester, 'Cancha 1, Techada').isSelected == Tristate.isTrue, isTrue);
      expect(
        flags(
          tester,
          '${days[tomorrow.weekday - 1]} ${tomorrow.day}',
        ).isSelected == Tristate.isTrue,
        isTrue,
      );
      expect(find.text('2 horas'), findsOneWidget);
      expect(flags(tester, '10:00 – 12:00').isSelected == Tristate.isTrue, isTrue);
      expect(flags(tester, 'CONTINUAR').isEnabled == Tristate.isTrue, isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'after querying, the filters stay visible and can be changed @CU-13-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, f5a, _, _) = await venueWithCourts();
      await openSearch(tester);
      await fillIn(tester, venue);
      await tapText(tester, 'CONSULTAR');
      await waitUntil(tester, find.text(f5a));

      // Verifies: what was picked stays in the filters.
      expect(find.text(venue), findsWidgets);
      expect(find.text(date(tomorrow)), findsOneWidget);

      await choose(tester, 'Hasta', '11:00');
      await tapText(tester, 'CONSULTAR');

      // Verifies: the new query uses the changed range.
      await waitUntil(
        tester,
        find.text('2 CANCHAS DISPONIBLES · FÚTBOL 5 · 10:00 – 11:00'),
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'no court is free in the range and sees the notice without losing the filters @CU-13-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, f5a, f5b, _) = await venueWithCourts();
      await occupy(f5a, tomorrow, 10, hours: 2);
      await occupy(f5b, tomorrow, 10);
      await openSearch(tester);
      await fillIn(tester, venue);

      await tapText(tester, 'CONSULTAR');

      // Verifies: the notice, and the filters stay filled in.
      await waitUntil(tester, find.text('No hay canchas disponibles'));
      expect(find.text(f5a), findsNothing);
      expect(find.text(venue), findsWidgets);
      expect(find.text(date(tomorrow)), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('picks a past date and no query is made @CU-13-H03-01', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final (venue, _, _, _) = await venueWithCourts();
    await openSearch(tester);

    await fillIn(tester, venue, day: yesterday);

    // Verifies: the error on the date and the query blocked.
    await waitUntil(tester, find.text('La fecha tiene que ser futura'));
    expect(flags(tester, 'CONSULTAR').isEnabled == Tristate.isTrue, isFalse);
    expect(find.textContaining('DISPONIBLE'), findsNothing);
    semantics.dispose();
  });

  testWidgets(
    'picks a range of less than one hour and no query is made @CU-13-H03-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _, _) = await venueWithCourts();
      await openSearch(tester);

      await fillIn(tester, venue, from: '18:00', to: '18:00');

      // Verifies: the error on the range and the query blocked.
      await waitUntil(tester, find.text('La duración mínima es de una hora'));
      expect(flags(tester, 'CONSULTAR').isEnabled == Tristate.isTrue, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'picks a range that ends after the venue closes and no query is made @CU-13-H03-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _, _) = await venueWithCourts();
      await openSearch(tester);

      await fillIn(tester, venue, from: '22:00', to: '00:00');

      // Verifies: the error with the closing time and the query blocked.
      await waitUntil(tester, find.text('La sede cierra a las 23:00'));
      expect(flags(tester, 'CONSULTAR').isEnabled == Tristate.isTrue, isFalse);
      semantics.dispose();
    },
  );

  testWidgets(
    'with no connection on querying, sees the error and keeps the filters @CU-13-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _, _, _) = await venueWithCourts();
      final api = await ProxyApi.open();
      await openSearch(tester, apiUrl: api.url);
      await fillIn(tester, venue);

      api.state = ApiState.offline;
      await tapText(tester, 'CONSULTAR');

      // Verifies: the error with retry, and the filters stay filled in.
      await waitUntil(
        tester,
        find.text('No se pudo consultar la disponibilidad'),
      );
      expect(find.textContaining('Revisá tu conexión'), findsOneWidget);
      expect(find.text('REINTENTAR'), findsOneWidget);
      expect(find.text(venue), findsWidgets);
      expect(find.text(date(tomorrow)), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the server fails on querying and no stale results are shown @CU-13-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, f5a, _, _) = await venueWithCourts();
      final api = await ProxyApi.open();
      await openSearch(tester, apiUrl: api.url);
      await fillIn(tester, venue);
      await tapText(tester, 'CONSULTAR');
      await waitUntil(tester, find.text(f5a));

      api.state = ApiState.failing;
      await tapText(tester, 'CONSULTAR');

      // Verifies: the error, and the previous result is gone.
      await waitUntil(
        tester,
        find.text('No se pudo consultar la disponibilidad'),
      );
      expect(find.text(f5a), findsNothing);
      expect(find.textContaining('CANCHAS DISPONIBLES'), findsNothing);
      semantics.dispose();
    },
  );
}
