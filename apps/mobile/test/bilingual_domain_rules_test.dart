import 'package:clubnahuelmosse/features/admin/domain/outside_hours.dart';
import 'package:clubnahuelmosse/features/admin/domain/space_price.dart';
import 'package:clubnahuelmosse/features/admin/domain/venue_problem.dart';
import 'package:clubnahuelmosse/features/admin/domain/venue_rules.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue.dart';
import 'package:clubnahuelmosse/features/venues/domain/venue_summary.dart';
import 'package:flutter_test/flutter_test.dart';

Venue _venue({
  String opening = '08:00',
  String closing = '23:00',
  List<int> days = const [1, 2, 3, 4, 5, 6, 7],
  List<String> sports = const [],
}) => Venue(
  id: 'v1',
  name: 'Morón',
  address: 'Calle 123',
  opening: opening,
  closing: closing,
  days: days,
  spaceCount: 2,
  sports: sports,
);

void main() {
  group('domain rules the admin forms rely on', () {
    test('venue form problems are plain enum members @ENG-19-ASM-05', () {
      expect(venueNameProblem('  '), VenueProblem.nameRequired);
      expect(venueNameProblem(' Club '), isNull);
      expect(venueAddressProblem(''), VenueProblem.addressRequired);
      expect(venueAddressProblem('Calle'), VenueProblem.addressStreetAndNumber);
      expect(
        venueAddressProblem('Calle 0'),
        VenueProblem.addressStreetAndNumber,
      );
      expect(venueAddressProblem(' Calle 123 '), isNull);
      expect(opensAtProblem(null), VenueProblem.opensAtRequired);
      expect(opensAtProblem(8), isNull);
      expect(
        closesAtProblem(closesAt: null, opensAt: 8),
        VenueProblem.closesAtRequired,
      );
      expect(
        closesAtProblem(closesAt: 8, opensAt: 8),
        VenueProblem.closesBeforeOpens,
      );
      expect(closesAtProblem(closesAt: 9, opensAt: 8), isNull);
      expect(closesAtProblem(closesAt: 0, opensAt: 8), isNull);
      expect(closesAtProblem(closesAt: 3, opensAt: null), isNull);
      expect(parseWholeHour('18:00'), 18);
      expect(parseWholeHour('18:30'), isNull);
      expect(parseWholeHour('18'), isNull);
    });

    test('the price per hour goes from 1 to the maximum @ENG-19-ASM-05', () {
      expect(validPricePerHour(null), isFalse);
      expect(validPricePerHour(0), isFalse);
      expect(validPricePerHour(1), isTrue);
      expect(validPricePerHour(maxPricePerHour), isTrue);
      expect(validPricePerHour(maxPricePerHour + 1), isFalse);
    });

    test('the sports of a venue follow the catalog order @ENG-19-S1', () {
      const catalog = Catalog([
        Sport('Futbol', 'Fútbol', []),
        Sport('Tenis', 'Tenis', []),
        Sport('Padel', 'Pádel', []),
      ]);
      expect(sportsOf(_venue(sports: ['Padel', 'Futbol']), catalog), [
        'Fútbol',
        'Pádel',
      ]);
      expect(sportsOf(_venue(), catalog), isEmpty);
    });

    test(
      'the weekdays label picks the option or the loose days @ENG-19-S1',
      () {
        expect(
          weekdaysLabel([7, 6, 5, 4, 3, 2, 1]).option,
          OpenDays.mondayToSunday,
        );
        expect(
          weekdaysLabel([1, 2, 3, 4, 5, 6]).option,
          OpenDays.mondayToSaturday,
        );
        expect(weekdaysLabel([1, 2, 3, 4, 5]).option, OpenDays.mondayToFriday);
        final loose = weekdaysLabel([6, 2, 2, 9, 0]);
        expect(loose.option, isNull);
        expect(loose.days, [2, 6]);
        expect(weekdaysLabel([2, 6]), weekdaysLabel([6, 2]));
        expect(weekdaysLabel([2, 6]), isNot(weekdaysLabel([2, 5])));
        expect(weekdaysLabel([2, 6]).hashCode, weekdaysLabel([6, 2]).hashCode);
        expect(weekdaysLabel([1, 2, 3, 4, 5]).days, isEmpty);
      },
    );

    test('what shrank in a venue tells why bookings fall out @ENG-19-S1', () {
      final shrunk = OutsideHours.of(
        3,
        before: _venue(days: [1, 2, 3]),
        opensAt: 10,
        closesAt: 20,
        openDays: [1, 2],
      );
      expect(shrunk.count, 3);
      expect(shrunk.venueName, 'Morón');
      expect(shrunk.reasons, OutsideReason.values);
      expect(shrunk.opensHour, '10:00');
      expect(shrunk.closesHour, '20:00');

      final same = OutsideHours.of(
        1,
        before: _venue(closing: '00:00'),
        opensAt: 8,
        closesAt: 0,
        openDays: [1, 2, 3, 4, 5, 6, 7],
      );
      expect(same.reasons, isEmpty);
      expect(same.closesHour, '00:00');

      final closesEarlier = OutsideHours.of(
        1,
        before: _venue(closing: '00:00'),
        opensAt: 8,
        closesAt: 23,
        openDays: [1, 2, 3, 4, 5, 6, 7],
      );
      expect(closesEarlier.reasons, [OutsideReason.endsAfter]);

      final unknown = OutsideHours.of(
        1,
        before: null,
        opensAt: 8,
        closesAt: 20,
        openDays: [1],
      );
      expect(unknown.venueName, isNull);
      expect(unknown.reasons, isEmpty);
    });

    test('a venue is read from the API JSON or it is null @ENG-19-S1', () {
      expect(Venue.fromJson(null), isNull);
      expect(Venue.fromJson({'id': 'v1'}), isNull);
      final venue = Venue.fromJson({
        'id': 'v1',
        'nombre': 'Morón',
        'direccion': 'Calle 123',
        'apertura': '08:00',
        'cierre': '23:00',
        'dias': [1, 2, 'x'],
        'canchas': 2,
        'deportes': ['Futbol', 3],
      })!;
      expect(venue.days, [1, 2]);
      expect(venue.sports, ['Futbol']);
      expect(venue.daysLabel, weekdaysLabel([1, 2]));
    });
  });
}
