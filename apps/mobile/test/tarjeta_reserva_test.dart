import 'dart:io';

import 'package:clubnahuelmosse/common/booking_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
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
        const BookingDateAndTime(
          date: 'sábado 7 de junio',
          time: '18:00 – 19:00',
        ),
        tema: darkTheme,
      );
      expect(find.text('sábado 7 de junio'), findsOneWidget);
      expect(find.text('18:00 – 19:00'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      for (final ruta in [
        'lib/features/admin/presentation/booking_detail.dart',
        'lib/features/bookings/presentation/booking_detail.dart',
      ]) {
        final codigo = File(ruta).readAsStringSync();
        expect(codigo, contains('common/booking_card.dart'), reason: ruta);
        expect(codigo, contains('BookingDateAndTime('), reason: ruta);
        expect(codigo, isNot(contains('Icons.schedule_rounded')), reason: ruta);
      }
    },
  );
}
