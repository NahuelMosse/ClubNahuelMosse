import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/espacios/espacio.dart';
import 'package:clubnahuelmosse/notificaciones/notificacion.dart';
import 'package:clubnahuelmosse/notificaciones/sistema.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sede.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

const _sede = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0001';
const _espacio = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0002';
const _reserva = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0003';
const _usuario = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0004';
const _aviso = '0192f3c4-7a10-7b2e-9c11-5d8e2a6f0005';

Map<String, Object?> _sedeJson() => {
  'id': _sede,
  'nombre': 'Sede Morón',
  'direccion': 'Av. Rivadavia 19850',
  'apertura': '08:00',
  'cierre': '23:00',
  'dias': [1, 2, 3, 4, 5, 6, 7],
  'canchas': 1,
  'deportes': ['Futbol'],
};

Map<String, Object?> _espacioJson() => {
  'id': _espacio,
  'nombre': 'Moron_Rivadavia_19850_Futbol_F5_1',
  'sede_id': _sede,
  'sede': 'Sede Morón',
  'deporte': 'Futbol',
  'tipo': 'F5',
  'numero': 1,
  'techada': false,
  'iluminada': true,
  'precio_por_hora': 38000,
};

Map<String, Object?> _reservaJson() => {
  'id': _reserva,
  'espacio_id': _espacio,
  'sede_id': _sede,
  'espacio': 'Moron_Rivadavia_19850_Futbol_F5_1',
  'deporte': 'Futbol',
  'tipo': 'F5',
  'sede': 'Sede Morón',
  'direccion': 'Av. Rivadavia 19850',
  'inicio': '2026-11-13T00:00:00Z',
  'fin': '2026-11-13T01:00:00Z',
  'total': 38000,
  'estado': 'activa',
  'motivo': null,
  'cancelable': true,
};

void main() {
  setUpAll(cargarFuentes);

  group('la app lee los ids como texto UUID y navega con ellos @DAT-01-S3', () {
    test('los modelos conservan el id como texto', () {
      expect(Sede.desdeJson(_sedeJson())?.id, _sede);
      final espacio = Espacio.desdeJson(_espacioJson());
      expect(espacio?.id, _espacio);
      expect(espacio?.sedeId, _sede);
      final reserva = Reserva.desdeJson(_reservaJson());
      expect(reserva?.id, _reserva);
      expect(reserva?.espacioId, _espacio);
      expect(reserva?.sedeId, _sede);
      final historial = ReservaHistorial.desdeJson({
        ..._reservaJson(),
        'usuario_id': _usuario,
        'usuario': 'Nahuel Mosse',
        'creado_en': '2026-11-01T10:00:00Z',
        'cancelada_en': null,
        'cancelada_por_nombre': null,
        'espacio_de_baja': false,
      });
      expect(historial?.id, _reserva);
      expect(historial?.usuarioId, _usuario);
      final aviso = Notificacion.desdeJson({
        'id': _aviso,
        'tipo': 'recordatorio',
        'titulo': 'Tu reserva es pronto',
        'cuerpo': 'Hoy',
        'creada_en': '2026-11-12T20:00:00Z',
        'leida': false,
        'reserva_id': _reserva,
      });
      expect(aviso?.id, _aviso);
      expect(aviso?.reservaId, _reserva);
    });

    test('un id numérico ya no es un id', () {
      expect(Sede.desdeJson({..._sedeJson(), 'id': 1}), isNull);
      expect(Espacio.desdeJson({..._espacioJson(), 'sede_id': 2}), isNull);
    });

    testWidgets('la ruta de una sede pide sus canchas con el UUID', (
      tester,
    ) async {
      final pedidos = <http.Request>[];
      await montarUsuario(
        tester,
        inicio: '/sedes/$_sede',
        api: apiRutas({
          'GET /espacios/catalogo': (200, catalogoJson),
          'GET /sedes': (200, '{"sedes": [${_json(_sedeJson())}]}'),
          'GET /espacios': (200, '{"espacios": [${_json(_espacioJson())}]}'),
        }, pedidos: pedidos),
      );
      expect(find.text('SEDE MORÓN'), findsOneWidget);
      final canchas = pedidos.where((p) => p.url.path == '/espacios').single;
      expect(canchas.url.queryParameters, {'sede_id': _sede});
    });
  });

  group('un aviso con reserva_id UUID abre la reserva y uno con reserva_id '
      'numérico abre el centro de notificaciones '
      '@assumption:DAT-01-ASM-05', () {
    test('un aviso con reserva_id UUID abre la reserva', () {
      final aviso = AvisoTocado.desdeDatos({
        'tipo': 'recordatorio',
        'reserva_id': _reserva,
      });
      expect(aviso.ruta, '/reservas?reserva=$_reserva');
    });

    test('uno con reserva_id numérico abre el centro de notificaciones', () {
      final aviso = AvisoTocado.desdeDatos({
        'tipo': 'recordatorio',
        'reserva_id': '7',
      });
      expect(aviso.ruta, '/notificaciones');
    });

    test('uno sin reserva_id abre Mis reservas', () {
      expect(AvisoTocado.desdeDatos({'tipo': 'recordatorio'}).ruta, '/reservas');
    });
  });
}

String _json(Map<String, Object?> m) => jsonEncode(m);
