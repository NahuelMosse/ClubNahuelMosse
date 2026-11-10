import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _json({
  String start = '2026-10-23T20:00:00Z',
  String end = '2026-10-23T21:00:00Z',
}) => {
  'id': '00000000-0000-7000-8000-000000000001',
  'space_id': '00000000-0000-7000-8000-000000000002',
  'venue_id': '00000000-0000-7000-8000-000000000003',
  'space': 'Cancha 1',
  'sport': 'Fútbol',
  'kind': 'F5',
  'venue': 'Sede',
  'address': 'Calle 1',
  'starts_at': start,
  'ends_at': end,
  'total': 1000,
  'status': 'active',
  'reason': null,
};

void main() {
  test('a valid ISO date is read in the club time', () {
    final r = bookingFromJson(_json());
    expect(r, isNotNull);
    expect(r!.startsAt, DateTime.utc(2026, 10, 23, 17));
    expect(r.endsAt, DateTime.utc(2026, 10, 23, 18));
  });

  test('a date that is not ISO invalidates the booking', () {
    expect(bookingFromJson(_json(start: 'mañana')), isNull);
    expect(bookingFromJson(_json(end: '')), isNull);
  });
}
