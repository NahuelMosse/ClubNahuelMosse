import 'package:clubnahuelmosse/comun/marcador.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/inicio/pantalla_inicio.dart';
import 'package:clubnahuelmosse/reservas/reservas.dart';
import 'package:clubnahuelmosse/sedes/sedes.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/tema/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide testWidgets;

import '../soporte/montar.dart';
import '../soporte/reloj_fijo.dart';

String _uuid(int n) =>
    '00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}';

String _reserva(int n) {
  final desde = DateTime.utc(2026, 11, 12, 21).add(Duration(days: n));
  final hasta = desde.add(const Duration(hours: 1));
  return '{"id": "${_uuid(n)}", "espacio_id": "${_uuid(9)}", "sede_id": "${_uuid(2)}", '
      '"espacio": "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", '
      '"tipo": "F5", "sede": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
      '"inicio": "${desde.toIso8601String()}", "fin": "${hasta.toIso8601String()}", '
      '"precio_por_hora": 38000, "total": 38000, "estado": "activa", '
      '"motivo": null, "cancelable": true}';
}

void main() {
  testWidgets(
    'con veinte próximas el marcador dice 20 en su celda PRÓXIMAS, en el color del texto sobre foto @RED-03-ASM-13',
    (tester) async {
      final sesion = SesionFalsa(perfilUsuario);
      final api = apiRutas({
        'GET /reservas': (
          200,
          '{"reservas": [${[for (var i = 1; i <= 20; i++) _reserva(i)].join(', ')}]}',
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

      final cifra = find.descendant(
        of: find.byType(Marcador),
        matching: find.text('20'),
      );
      expect(cifra, findsOneWidget);
      expect(find.text('20+'), findsNothing);
      expect(
        tester.widget<Text>(cifra).style?.color,
        Paleta.oscura.accentOnMedia,
      );
    },
  );
}
