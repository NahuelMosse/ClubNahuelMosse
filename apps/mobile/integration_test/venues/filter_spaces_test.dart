import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A venue with two «Fútbol 5», one «Fútbol 7» and one «Hockey 7», and the name of each court.
  Future<(String, Map<String, String>)> venueWithCourts() async {
    final venue = 'Sede Ituzaingó ${unique()}';
    await createVenue(venue, 'Av. Ratti 1400');
    return (
      venue,
      {
        'F5_1': await createSpace(venue),
        'F5_2': await createSpace(venue),
        'F7_1': await createSpace(venue, kind: 'F7'),
        'H7_1': await createSpace(venue, sport: 'Hockey', kind: 'H7'),
      },
    );
  }

  Future<void> enterVenue(
    WidgetTester tester,
    String venue, {
    String? apiUrl,
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
    await waitUntil(tester, find.text('4 CANCHAS · TODOS LOS DEPORTES'));
  }

  Future<void> filterBy(WidgetTester tester, String chip) async {
    final button = find.bySemanticsLabel(chip);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  bool picked(WidgetTester tester, String chip) => tester
      .getSemantics(find.bySemanticsLabel(chip))
      .flagsCollection
      .isSelected == Tristate.isTrue;

  testWidgets(
    'picks a sport in a venue and only sees the courts of that sport, with the counter @CU-20-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, courts) = await venueWithCourts();
      await enterVenue(tester, venue);

      await filterBy(tester, 'Deporte Fútbol');

      // Verifies: the counter names the sport and only its courts remain.
      await waitUntil(
        tester,
        find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );
      expect(picked(tester, 'Deporte Fútbol'), isTrue);
      for (final c in ['F5_1', 'F5_2', 'F7_1']) {
        expect(find.text(courts[c]!), findsOneWidget);
      }
      expect(find.text(courts['H7_1']!), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'picks a variant and only sees the courts of that type, with the counter updated @CU-20-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, courts) = await venueWithCourts();
      await enterVenue(tester, venue);
      await filterBy(tester, 'Deporte Fútbol');
      await waitUntil(
        tester,
        find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );

      await filterBy(tester, 'Tipo Fútbol 5');

      // Verifies: only the Fútbol 5 ones, with the counter of the type.
      await waitUntil(tester, find.text('2 CANCHAS · FÚTBOL 5'));
      expect(picked(tester, 'Tipo Fútbol 5'), isTrue);
      expect(find.text(courts['F5_1']!), findsOneWidget);
      expect(find.text(courts['F5_2']!), findsOneWidget);
      expect(find.text(courts['F7_1']!), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'a court just created shows up when filtering by its sport and its type @CU-20-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _) = await venueWithCourts();
      await enterVenue(tester, venue);

      // The administrator loads another court while the user looks at the venue.
      final added = await createSpace(venue, kind: 'F7');
      await filterBy(tester, 'Deporte Fútbol');
      await waitUntil(
        tester,
        find.text('4 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );
      await filterBy(tester, 'Tipo Fútbol 7');

      // Verifies: the new one shows among those of its type.
      await waitUntil(tester, find.text('2 CANCHAS · FÚTBOL 7'));
      expect(find.text(added), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the picked filter is kept while still in the venue @CU-20-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, _) = await venueWithCourts();
      await enterVenue(tester, venue);
      await filterBy(tester, 'Deporte Fútbol');
      await waitUntil(
        tester,
        find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );
      await filterBy(tester, 'Tipo Fútbol 5');
      await waitUntil(tester, find.text('2 CANCHAS · FÚTBOL 5'));

      // Goes on to the times of a court and returns to the venue.
      final book = find.text('VER HORARIOS / RESERVAR').first;
      await tester.ensureVisible(book);
      await tester.pumpAndSettle();
      await tester.tap(book);
      await tester.pumpAndSettle();
      await waitUntil(tester, find.text('SELECCIONÁ CANCHA'));
      await tapText(tester, 'Sedes');

      // Verifies: the venue is still filtered by «Fútbol 5».
      await waitUntil(tester, find.text('2 CANCHAS · FÚTBOL 5'));
      expect(picked(tester, 'Deporte Fútbol'), isTrue);
      expect(picked(tester, 'Tipo Fútbol 5'), isTrue);
      semantics.dispose();
    },
  );

  testWidgets(
    'picks a sport with a single mode and the variant bar does not appear @CU-20-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, courts) = await venueWithCourts();
      await enterVenue(tester, venue);

      await filterBy(tester, 'Deporte Hockey');

      // Verifies: filters by sport and offers no types.
      await waitUntil(tester, find.text('1 CANCHA · HOCKEY'));
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      expect(find.text(courts['H7_1']!), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'taps «Todos» and sees all the courts of the sport again, without losing the sport @CU-20-H03-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, courts) = await venueWithCourts();
      await enterVenue(tester, venue);
      await filterBy(tester, 'Deporte Fútbol');
      await waitUntil(
        tester,
        find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );
      await filterBy(tester, 'Tipo Fútbol 7');
      await waitUntil(tester, find.text('1 CANCHA · FÚTBOL 7'));

      await filterBy(tester, 'Tipo Todos');

      // Verifies: all the Fútbol ones are back and the sport stays picked.
      await waitUntil(
        tester,
        find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );
      expect(picked(tester, 'Deporte Fútbol'), isTrue);
      expect(picked(tester, 'Tipo Todos'), isTrue);
      expect(find.text(courts['F5_1']!), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'enters a venue with no courts and sees no chips, only the notice @CU-20-H04-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final venue = 'Sede Haedo ${unique()}';
      await createVenue(venue, 'Av. Vergara 1850');
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await tapText(tester, 'SEDES');
      final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(venue)},'));
      await waitUntil(tester, card);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Verifies: the notice and no filter.
      await waitUntil(tester, find.text('Todavía no hay canchas'));
      expect(find.text('DEPORTE'), findsNothing);
      expect(find.text('TIPO DE CANCHA'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'with no connection on filtering, sees the alert and the listing does not change @CU-20-H05-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, courts) = await venueWithCourts();
      final api = await ProxyApi.open();
      await enterVenue(tester, venue, apiUrl: api.url);

      api.state = ApiState.offline;
      await filterBy(tester, 'Deporte Fútbol');

      // Verifies: warns of no connection and the listing keeps all the sports.
      await waitUntil(tester, find.text('Error de conexión'));
      await tapText(tester, 'Volver');
      expect(find.text('4 CANCHAS · TODOS LOS DEPORTES'), findsOneWidget);
      expect(picked(tester, 'Deporte Fútbol'), isFalse);
      expect(find.text(courts['H7_1']!), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the server fails on filtering, sees the error and the listing does not change @CU-20-H06-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, courts) = await venueWithCourts();
      final api = await ProxyApi.open();
      await enterVenue(tester, venue, apiUrl: api.url);
      await filterBy(tester, 'Deporte Fútbol');
      await waitUntil(
        tester,
        find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'),
      );

      api.state = ApiState.failing;
      await filterBy(tester, 'Tipo Fútbol 5');

      // Verifies: warns of the server and the previous filter stays.
      await waitUntil(tester, find.text('Error del servidor'));
      await tapText(tester, 'ACEPTAR');
      expect(find.text('3 CANCHAS · FÚTBOL · TODOS LOS TIPOS'), findsOneWidget);
      expect(picked(tester, 'Tipo Fútbol 5'), isFalse);
      expect(find.text(courts['F7_1']!), findsOneWidget);
      semantics.dispose();
    },
  );
}
