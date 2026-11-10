import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../support/actions.dart';
import '../support/network.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// A venue owned by the test and the part of the composed name that belongs to it.
  Future<(String, String)> ownVenue() async {
    final s = unique();
    await createVenue('Sede Haedo $s', 'Av. Vergara 1850');
    return ('Sede Haedo $s', 'Haedo${s}_Vergara_1850');
  }

  /// A venue with two «Fútbol 5» and one «Hockey 7».
  Future<(String, String)> venueWithCourts() async {
    final (venue, prefix) = await ownVenue();
    await createSpace(venue);
    await createSpace(venue);
    await createSpace(venue, sport: 'Hockey', kind: 'H7');
    return (venue, prefix);
  }

  Future<void> goTo(WidgetTester tester, String venue, String counter) async {
    await tapText(tester, 'SEDES');
    final card = find.bySemanticsLabel(RegExp('^${RegExp.escape(venue)},'));
    await waitUntil(tester, card);
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();
    await waitUntil(tester, find.text(counter));
  }

  Future<void> filter(WidgetTester tester, String chip) async {
    final button = find.bySemanticsLabel(chip);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  /// The administrator panel card for the space [name] of the venue [venue].
  Finder panelCard(String venue, String name) => find.bySemanticsLabel(
    RegExp('${RegExp.escape(venue)}, ${RegExp.escape(name)}\$'),
  );

  testWidgets(
    'on each venue screen, each space is shown with its venue and its address @TP-05-H01-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await venueWithCourts();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await goTo(tester, venue, '3 CANCHAS · TODOS LOS DEPORTES');

      // Verifies: the venue and its address head its courts, and each one carries them in its name.
      expect(find.text(venue.toUpperCase()), findsOneWidget);
      expect(find.textContaining('AV. VERGARA 1850'), findsOneWidget);
      for (final n in ['Futbol_F5_1', 'Futbol_F5_2', 'Hockey_H7_1']) {
        expect(find.text('${prefix}_$n'), findsOneWidget);
      }
      semantics.dispose();
    },
  );

  testWidgets(
    'each space shows its name composed of venue, address, kind and number @TP-05-H01-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      final one = await createSpace(venue, sport: 'Padel', kind: 'PAD');
      final two = await createSpace(venue, sport: 'Padel', kind: 'PAD');
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');

      await goTo(tester, venue, '2 CANCHAS · TODOS LOS DEPORTES');

      // Verifies: venue, street, number, sport, kind and ordinal, in that order.
      expect(one, '${prefix}_Padel_PAD_1');
      expect(two, '${prefix}_Padel_PAD_2');
      expect(find.text(one), findsOneWidget);
      expect(find.text(two), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'the administrator panel lists the spaces of all the venues, each with its venue @TP-05-H01-03',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (haedo, _) = await ownVenue();
      final s = unique();
      await createVenue('Sede Ramos $s', 'Av. Vergara 1850');
      final inHaedo = await createSpace(haedo);
      final inRamos = await createSpace('Sede Ramos $s', kind: 'F7');
      await signInAsAdmin(tester);

      await tapText(tester, 'ESPACIOS');

      // Verifies: the spaces of the two venues, each with its own.
      for (final (venue, name) in [
        (haedo, inHaedo),
        ('Sede Ramos $s', inRamos),
      ]) {
        final card = panelCard(venue, name);
        await waitUntil(tester, card);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        expect(find.text(name), findsOneWidget);
      }
      expect(find.textContaining('ESPACIOS ACTIVOS ·'), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'a newly created space appears in its venue and in the administrator panel @TP-05-H01-04',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await ownVenue();
      final name = '${prefix}_Voley_PLA_1';
      await signInAsAdmin(tester);
      await tapText(tester, 'ESPACIOS');
      await tapText(tester, 'ALTA ESPACIO');
      await waitUntil(tester, find.text('Nuevo espacio deportivo'));
      await choose(tester, 'Sede', venue);
      await choose(tester, 'Deporte', 'Vóley');
      await choose(tester, 'Tipo', 'Vóley playa');
      await choose(tester, 'Condición', 'Al aire libre');
      await choose(tester, 'Iluminación', 'Sin iluminación');
      await typeInto(tester, 'Precio por hora', '29000');
      await tapText(tester, 'GUARDAR ESPACIO');
      await waitUntil(tester, find.text('¡Espacio deportivo creado!'));

      await tapText(tester, 'IR AL LISTADO');

      // Verifies: the panel already lists it with its venue.
      final card = panelCard(venue, name);
      await waitUntil(tester, card);

      // Verifies: a user sees it on the venue screen.
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await goTo(tester, venue, '1 CANCHA · TODOS LOS DEPORTES');
      expect(find.text(name), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets(
    'inside a venue it filters by kind and sees only the spaces of that kind @TP-05-H02-01',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await venueWithCourts();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await goTo(tester, venue, '3 CANCHAS · TODOS LOS DEPORTES');

      await filter(tester, 'Deporte Hockey');

      // Verifies: only the hockey one is left.
      await waitUntil(tester, find.text('1 CANCHA · HOCKEY'));
      expect(find.text('${prefix}_Hockey_H7_1'), findsOneWidget);
      expect(find.text('${prefix}_Futbol_F5_1'), findsNothing);
      expect(find.text('${prefix}_Futbol_F5_2'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'removes the filter and sees all the spaces of the venue again @TP-05-H02-02',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final (venue, prefix) = await venueWithCourts();
      await signInAsUser(tester, email: 'socio.${unique()}@correo.com');
      await goTo(tester, venue, '3 CANCHAS · TODOS LOS DEPORTES');
      await filter(tester, 'Deporte Fútbol');
      await waitUntil(tester, find.text('2 CANCHAS · FÚTBOL'));

      await filter(tester, 'Deporte Fútbol');

      // Verifies: the three courts are back, with no sport chosen.
      await waitUntil(tester, find.text('3 CANCHAS · TODOS LOS DEPORTES'));
      for (final n in ['Futbol_F5_1', 'Futbol_F5_2', 'Hockey_H7_1']) {
        expect(find.text('${prefix}_$n'), findsOneWidget);
      }
      semantics.dispose();
    },
  );
}
