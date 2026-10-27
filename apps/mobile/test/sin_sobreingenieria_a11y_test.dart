import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_panel_admin.dart';
import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'kit/kit_a11y.dart';
import 'mis_reservas_test.dart' show reservaJson;
import 'soporte/admin.dart';
import 'soporte/montar.dart';
import 'soporte/usuario.dart';

void main() {
  setUpAll(cargarFuentes);

  testWidgets('Mis reservas cumple las guías de accesibilidad @SIM-01-S1', (
    tester,
  ) async {
    final rutas = rutasDeSedes();
    await montarUsuario(
      tester,
      inicio: '/reservas',
      api: ClienteApi(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          final (c, cuerpo) = pedido.url.path == '/reservas'
              ? (
                  200,
                  '{"reservas": ${pedido.url.queryParameters['cuando'] == 'historial' ? '[${reservaJson(id: 2, estado: 'cancelada', motivo: 'Lluvia')}]' : '[${reservaJson()}]'}}',
                )
              : rutas['${pedido.method} ${pedido.url.path}'] ?? (404, '{}');
          return http.Response.bytes(
            utf8.encode(cuerpo),
            c,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      ),
    );

    await kitA11y(tester);
  });

  testWidgets('Inicio cumple las guías de accesibilidad @SIM-01-S1', (
    tester,
  ) async {
    await montar(
      tester,
      inicioFalso(SesionFalsa(perfilUsuario)),
      tema: temaOscuro,
    );

    await kitA11y(tester);
  });

  testWidgets(
    'el listado de reservas del admin cumple las guías de accesibilidad @SIM-01-S2',
    (tester) async {
      const reserva =
          '{"id": 1, "espacio_id": 9, "sede_id": 1, "espacio":'
          ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
          ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
          ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
          ' "estado": "activa", "motivo": null, "usuario_id": 1, "usuario": "Nahuel Mosse",'
          ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
          ' "cancelada_por_nombre": null, "espacio_de_baja": false}';
      final api = apiRutas({
        'GET /reservas/todas': (
          200,
          '{"reservas": [$reserva], "total": 1, "pagina": 1,'
              ' "por_pagina": 20, "contadores": {"todas": 1, "activas": 1,'
              ' "completadas": 0, "anuladas": 0}}',
        ),
        'GET /espacios/catalogo': (200, catalogoJson),
      });
      final sesion = SesionFalsa(perfilAdmin);
      await montar(
        tester,
        PantallaPanelAdmin(
          historial: HistorialDeReservas(api: api, sesion: sesion),
          sedes: Sedes(api: api, sesion: sesion),
          espacios: Espacios(api: api, sesion: sesion),
          sesion: sesion,
          pendientes: FiltrosDePanelPendientes(),
        ),
        tema: temaOscuro,
      );

      await kitA11y(tester);
    },
  );
}
