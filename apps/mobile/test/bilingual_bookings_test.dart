import 'package:clubnahuelmosse/features/bookings/domain/search_rules.dart';
import 'package:clubnahuelmosse/features/bookings/presentation/search_problem_texts.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/space_texts.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:clubnahuelmosse/features/venues/presentation/venue_texts.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _english = [Locale('en', 'US')];
const _venueId = '00000000-0000-7000-8000-000000000001';
const _spaceId = '00000000-0000-7000-8000-000000000009';

void main() {
  setUpAll(cargarFuentes);

  Future<void> open(WidgetTester tester, String route) async {
    tester.platformDispatcher.localesTestValue = _english;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await montarUsuario(
      tester,
      inicio: route,
      api: apiRutas({
        ...rutasDeSedes(),
        'POST /bookings': (201, reservaJson()),
        'GET /bookings': (200, '{"bookings": [${reservaJson()}]}'),
      }),
    );
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  void expectTexts(Iterable<String> texts) {
    for (final text in texts) {
      expect(find.text(text), findsWidgets, reason: text);
    }
  }

  testWidgets(
    'booking, availability, space search and my bookings show English @ENG-19-S1',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await open(tester, '/inicio/buscar');
      expectTexts([
        'Find a court',
        'Check courts',
        'Pick a venue, a sport and a time range. Whole hours only, 1 to 4 hours.',
        'VENUE',
        'SPORT',
        'COURT TYPE',
        'DATE',
        'FROM',
        'TO',
        'Select a venue',
        'Select a sport',
        'DD / MM / YYYY',
        'CLEAR',
        'SEARCH',
      ]);
      expect(find.bySemanticsLabel('Venue'), findsOneWidget);
      expect(find.text('SEDE'), findsNothing);
      expect(find.text('CONSULTAR'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await open(tester, '/sedes/$_venueId/canchas/$_spaceId');
      expectTexts([
        'SELECT A COURT',
        'Court 1',
        'Open air',
        'DATE',
        'DURATION',
        'Whole hours, 1 to 4 h. The venue closes at 23:00.',
        'AVAILABLE TIME',
        'Some times are already taken · 6 unavailable',
        'No time chosen',
        'TOTAL',
        'CONTINUE',
      ]);
      expect(find.bySemanticsLabel('One hour less'), findsOneWidget);
      expect(find.bySemanticsLabel('One hour more'), findsOneWidget);
      await tapText(tester, '18:00 – 19:00');
      await tapText(tester, 'CONTINUE');
      expectTexts([
        'Confirm your booking',
        'CONFIRM BOOKING',
        'Court 1 · Open air',
        'Date',
        'Time',
        'CANCEL',
      ]);
      await tapText(tester, 'CONFIRM BOOKING');
      expectTexts([
        'Booking confirmed!',
        'GAME ON!',
        'See you there. We\'ll remind you an hour before.',
        '21:00 – 22:00 · 1 hour',
        'Space',
        'SEE MY BOOKINGS',
        'Back to home',
      ]);
      expect(find.bySemanticsLabel('Step 3 of 3: Done!'), findsOneWidget);

      await tapText(tester, 'SEE MY BOOKINGS');
      expectTexts(['Upcoming', 'History', 'MODIFY', 'CANCEL', 'ACTIVE']);
      expect(find.text('Próximas'), findsNothing);
      await tapText(tester, 'CANCEL');
      expectTexts(['Cancel the booking?', 'CANCEL BOOKING', 'DON\'T CANCEL']);
      expect(find.textContaining('The slot becomes free again.'), findsOne);
      semantics.dispose();
    },
  );

  testWidgets('venues and their spaces show English @ENG-19-S1', (
    tester,
  ) async {
    await open(tester, '/sedes');
    expectTexts([
      'Venues',
      '2 venues · 2 courts · each with its own hours',
      'Monday to Sunday · 08:00 to 23:00',
      'See courts',
    ]);
    expect(find.text('Sedes'), findsNothing);

    await tapText(tester, 'Sede Morón');
    expectTexts([
      'All venues',
      'SPORT',
      '2 COURTS · ALL SPORTS',
      'Open air',
      'Lit',
      'Unlit',
      '/ HOUR',
      'SEE TIMES / BOOK',
      'Fútbol 5 · Open air · with lighting',
    ]);
    expect(
      find.textContaining('Fútbol 5 · Open air · with lighting'),
      findsOne,
    );
  });

  test(
    'the venue days, the space lighting and the search errors the domain decides show in English and in Spanish @ENG-19-ASM-05',
    () async {
      await initializeDateFormatting();
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final es = await AppLocalizations.delegate.load(const Locale('es'));

      for (final (days, english, spanish) in [
        ([1, 2, 3, 4, 5, 6, 7], 'Monday to Sunday', 'Lunes a domingo'),
        ([1, 2, 3, 4, 5, 6], 'Monday to Saturday', 'Lunes a sábado'),
        ([1, 2, 3, 4, 5], 'Monday to Friday', 'Lunes a viernes'),
      ]) {
        expect(weekdaysText(en, weekdaysLabel(days)), english);
        expect(weekdaysText(es, weekdaysLabel(days)), spanish);
      }
      expect(weekdaysText(en, weekdaysLabel([1, 3])), 'Mon, Wed');
      expect(weekdaysText(es, weekdaysLabel([1, 3])), 'Lun, Mié');
      expect(
        weekdaysLabel([6, 7, 1, 2, 3, 4, 5]),
        weekdaysLabel([1, 2, 3, 4, 5, 6, 7]),
      );

      final space = Space.fromJson({
        'id': _spaceId,
        'nombre': 'Moron_Rivadavia_19850_Futbol_F5_1',
        'sede_id': _venueId,
        'sede': 'Sede Morón',
        'deporte': 'Futbol',
        'tipo': 'F5',
        'numero': 1,
        'techada': true,
        'iluminada': false,
        'precio_por_hora': 38000,
      })!;
      expect(conditionText(en, space), 'Covered');
      expect(conditionText(es, space), 'Techada');
      expect(lightingText(en, space), 'Unlit');
      expect(lightingText(es, space), 'Sin iluminación');

      final venue = Venue.fromJson({
        'id': _venueId,
        'nombre': 'Sede Morón',
        'direccion': 'Av. Rivadavia 19850',
        'apertura': '08:00',
        'cierre': '23:00',
        'dias': [1, 2, 3, 4, 5, 6],
        'canchas': 2,
      })!;
      final now = DateTime.utc(2026, 11, 12, 18, 20);
      final thursday = DateTime.utc(2026, 11, 12);
      final friday = thursday.add(const Duration(days: 1));
      Map<String, RangeProblem> errors(DateTime day, int from, int to) =>
          rangeErrors(venue: venue, day: day, from: from, to: to, now: now);

      for (final (problem, english, spanish) in [
        (
          errors(thursday.subtract(const Duration(days: 1)), 19, 20)['fecha'],
          'The date must be in the future',
          'La fecha tiene que ser futura',
        ),
        (
          errors(thursday.add(const Duration(days: 7)), 19, 20)['fecha'],
          'Pick a day within the next 7',
          'Elegí un día de los próximos 7',
        ),
        (
          errors(thursday.add(const Duration(days: 3)), 19, 20)['fecha'],
          'The venue is closed that day',
          'La sede no abre ese día',
        ),
        (
          errors(friday, 18, 18)['hasta'],
          'The minimum duration is one hour',
          'La duración mínima es de una hora',
        ),
        (
          errors(friday, 10, 15)['hasta'],
          'The maximum duration is 4 hours',
          'La duración máxima es de 4 horas',
        ),
        (
          errors(friday, 22, 0)['hasta'],
          'The venue closes at 23:00',
          'La sede cierra a las 23:00',
        ),
        (
          errors(friday, 7, 9)['desde'],
          'The venue opens at 08:00',
          'La sede abre a las 08:00',
        ),
        (
          errors(thursday, 18, 19)['desde'],
          'The time must be in the future',
          'El horario tiene que ser futuro',
        ),
      ]) {
        expect(problem, isNotNull, reason: spanish);
        expect(rangeProblemText(en, problem!), english);
        expect(rangeProblemText(es, problem), spanish);
      }
      expect(errors(friday, 19, 21), isEmpty);
    },
  );
}
