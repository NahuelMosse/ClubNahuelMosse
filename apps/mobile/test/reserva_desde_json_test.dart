import 'package:clubnahuelmosse/features/bookings/data/booking_json.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> _json({
  String inicio = '2026-10-23T20:00:00Z',
  String fin = '2026-10-23T21:00:00Z',
}) => {
  'id': '00000000-0000-7000-8000-000000000001',
  'espacio_id': '00000000-0000-7000-8000-000000000002',
  'sede_id': '00000000-0000-7000-8000-000000000003',
  'espacio': 'Cancha 1',
  'deporte': 'Fútbol',
  'tipo': 'F5',
  'sede': 'Sede',
  'direccion': 'Calle 1',
  'inicio': inicio,
  'fin': fin,
  'total': 1000,
  'estado': 'activa',
  'motivo': null,
};

void main() {
  test('una fecha ISO válida se lee en la hora del club', () {
    final r = bookingFromJson(_json());
    expect(r, isNotNull);
    expect(r!.startsAt, DateTime.utc(2026, 10, 23, 17));
    expect(r.endsAt, DateTime.utc(2026, 10, 23, 18));
  });

  test('una fecha que no es ISO invalida la reserva', () {
    expect(bookingFromJson(_json(inicio: 'mañana')), isNull);
    expect(bookingFromJson(_json(fin: '')), isNull);
  });
}
