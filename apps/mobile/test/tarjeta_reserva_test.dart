import 'dart:io';

import 'package:clubnahuelmosse/comun/tarjeta_reserva.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'el panel admin y Mis reservas muestran la reserva con la misma tarjeta @REV-06-S5 @assumption:REV-06-ASM-04',
    (tester) async {
      await montar(
        tester,
        const FechaYHorario(fecha: 'sábado 7 de junio', horario: '18:00 – 19:00'),
        tema: temaOscuro,
      );
      expect(find.text('sábado 7 de junio'), findsOneWidget);
      expect(find.text('18:00 – 19:00'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      for (final ruta in [
        'lib/admin/pantalla_panel_admin.dart',
        'lib/reservas/pantalla_mis_reservas.dart',
      ]) {
        final codigo = File(ruta).readAsStringSync();
        expect(codigo, contains('comun/tarjeta_reserva.dart'), reason: ruta);
        expect(codigo, contains('FechaYHorario('), reason: ruta);
        expect(codigo, isNot(contains('Icons.schedule_rounded')), reason: ruta);
      }
    },
  );
}
