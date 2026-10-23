import 'package:flutter_test/flutter_test.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';

Map<String, Object?> _json({String inicio = '2026-10-23T20:00:00Z', String fin = '2026-10-23T21:00:00Z'}) => {
  'id': 1,
  'espacio_id': 2,
  'sede_id': 3,
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
    final r = Reserva.desdeJson(_json());
    expect(r, isNotNull);
    expect(r!.inicio, DateTime.utc(2026, 10, 23, 17));
    expect(r.fin, DateTime.utc(2026, 10, 23, 18));
  });

  test('una fecha que no es ISO invalida la reserva', () {
    expect(Reserva.desdeJson(_json(inicio: 'mañana')), isNull);
    expect(Reserva.desdeJson(_json(fin: '')), isNull);
  });
}
