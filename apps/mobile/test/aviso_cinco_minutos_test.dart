import 'package:clubnahuelmosse/notificaciones/notificacion.dart';
import 'package:clubnahuelmosse/notificaciones/tarjeta_aviso.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

const _reserva = '00000000-0000-7000-8000-000000000007';

Notificacion _aviso(String tipo) => Notificacion.desdeJson({
  'id': '00000000-0000-7000-8000-000000000001',
  'tipo': tipo,
  'titulo': 'Tu reserva empieza en 5 minutos',
  'cuerpo': 'Fútbol 5 · Sede Morón · 21:00 – 22:00',
  'reserva_id': _reserva,
  'creada_en': '2026-11-12T23:55:00Z',
  'leida': false,
})!;

void main() {
  testWidgets(
    'el aviso de 5 minutos se muestra con el ícono del recordatorio y abre la reserva @NOT-05-S2',
    (tester) async {
      final cinco = _aviso('recordatorio_cinco');
      expect(cinco.tipo, TipoDeNotificacion.recordatorioCinco);
      expect(
        rutaDelAviso(cinco.tipo, cinco.reservaId),
        rutaDelAviso(TipoDeNotificacion.recordatorio, _reserva),
      );
      var toques = 0;
      await montar(
        tester,
        Scaffold(
          body: TarjetaAviso(
            notificacion: cinco,
            ahora: DateTime.utc(2026, 11, 12, 20),
            alTocar: () => toques++,
          ),
        ),
        tema: temaClaro,
      );
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      await tester.tap(find.byType(TarjetaAviso));
      expect(toques, 1);
    },
  );
}
