import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'anular_reserva_test.dart' show reservaJson;
import 'soporte/montar.dart';

void main() {
  String pagina(int numero, String? siguiente) =>
      '{"reservas": [${reservaJson()}], "total": 45, "pagina": $numero,'
      ' "por_pagina": 20, "siguiente": ${siguiente == null ? 'null' : '"$siguiente"'},'
      ' "contadores": {"todas": 45, "activas": 45, "completadas": 0, "anuladas": 0}}';

  test(
    'el historial global del admin trae la tanda siguiente y conserva la posición @REV-03-S3',
    () async {
      final pedidos = <Uri>[];
      final api = ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          pedidos.add(pedido.url);
          final cuerpo = switch (pedido.url.queryParameters['despues']) {
            null => pagina(1, 'marcador-1'),
            'marcador-1' => pagina(2, 'marcador-2'),
            _ => '{}',
          };
          return http.Response.bytes(
            utf8.encode(cuerpo),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final historial = HistorialDeReservas(
        api: api,
        sesion: SesionFalsa(perfilAdmin),
      );

      await historial.pagina(const FiltrosDeHistorial());
      final segunda = await historial.pagina(
        const FiltrosDeHistorial(),
        pagina: 2,
      );

      expect(pedidos.first.queryParameters.containsKey('despues'), isFalse);
      expect(pedidos.last.queryParameters['despues'], 'marcador-1');
      expect(pedidos.last.queryParameters['pagina'], '2');
      expect(segunda.pagina, 2);
      expect(segunda.hayMasPaginas, isTrue);
    },
  );
}
