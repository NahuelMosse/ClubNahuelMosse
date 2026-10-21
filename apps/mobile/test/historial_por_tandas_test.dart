import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/usuario.dart';

void main() {
  String tanda(Iterable<int> ids, String? siguiente) =>
      '{"reservas": [${ids.map((id) => reservaJson(id: id, estado: 'cancelada', motivo: 'Lluvia $id')).join(',')}], '
      '"siguiente": ${siguiente == null ? 'null' : '"$siguiente"'}}';

  testWidgets(
    'el historial propio trae la tanda siguiente al llegar al final @REV-03-H10-02',
    (tester) async {
      final pedidos = <http.Request>[];
      final rutas = rutasDeSedes();
      // Un servidor falso que entrega el historial en dos tandas: 20 y, con el marcador, 5.
      final respuestas = {
        null: tanda(List.generate(20, (i) => i + 1), 'marcador-20'),
        'marcador-20': tanda(List.generate(5, (i) => i + 21), null),
      };
      await montarUsuario(
        tester,
        inicio: '/reservas',
        api: ClienteApi(
          'http://api.falsa',
          cliente: MockClient((pedido) async {
            pedidos.add(pedido);
            final consulta = pedido.url.queryParameters;
            final (codigo, cuerpo) = pedido.url.path == '/reservas'
                ? (
                    200,
                    consulta['cuando'] == 'historial'
                        ? respuestas[consulta['despues']] ?? '{}'
                        : '{"reservas": [], "siguiente": null}',
                  )
                : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
            return http.Response.bytes(
              utf8.encode(cuerpo),
              codigo,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        ),
      );
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.textContaining('Lluvia 25'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Lluvia 25'), findsOneWidget);
      expect(
        pedidos.where((p) => p.url.queryParameters['despues'] == 'marcador-20'),
        hasLength(1),
      );
    },
  );
}
