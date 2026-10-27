import 'package:clubnahuelmosse/comun/marcador.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

String _reserva(int id) {
  final desde = DateTime.utc(2026, 11, 12, 24).add(Duration(days: id));
  final hasta = desde.add(const Duration(hours: 1));
  return '{"id": $id, "espacio_id": 9, "sede_id": 2, '
      '"espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", '
      '"tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
      '"inicio": "${desde.toIso8601String()}", "fin": "${hasta.toIso8601String()}", '
      '"precio_por_hora": 38000, "total": 38000, "estado": "activa", '
      '"motivo": null, "cancelable": true}';
}

void main() {
  testWidgets(
    'inicio el marcador de próximas muestra la cantidad de reservas próximas @RED-03-ASM-13',
    (tester) async {
      final sesion = SesionFalsa(perfilUsuario);
      final api = apiRutas({
        'GET /reservas': (
          200,
          '{"reservas": [${[for (var i = 1; i <= 23; i++) _reserva(i)].join(', ')}]}',
        ),
        'GET /espacios/catalogo': (200, '{"deportes": []}'),
        'GET /sedes': (200, '{"sedes": []}'),
      });
      await montar(
        tester,
        PantallaInicio(
          sesion: sesion,
          reservas: Reservas(api: api, sesion: sesion),
          espacios: Espacios(api: api, sesion: sesion),
          sedes: Sedes(api: api, sesion: sesion),
        ),
        tema: temaOscuro,
        tamano: const Size(393, 852),
      );

      expect(
        find.descendant(
          of: find.byType(Marcador),
          matching: find.text('23'),
        ),
        findsOneWidget,
      );
    },
  );
}
