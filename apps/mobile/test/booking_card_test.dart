import 'dart:io';

import 'package:clubnahuelmosse/common/booking_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mount.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets(
    'the admin panel and «Mis reservas» show the booking with the same card @REV-06-S5 @assumption:REV-06-ASM-04',
    (tester) async {
      await mountScreen(
        tester,
        const BookingDateAndTime(
          date: 'sábado 7 de junio',
          time: '18:00 – 19:00',
        ),
        theme: darkTheme,
      );
      expect(find.text('sábado 7 de junio'), findsOneWidget);
      expect(find.text('18:00 – 19:00'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);

      for (final path in [
        'lib/features/admin/presentation/booking_detail.dart',
        'lib/features/bookings/presentation/booking_detail.dart',
      ]) {
        final code = File(path).readAsStringSync();
        expect(code, contains('common/booking_card.dart'), reason: path);
        expect(code, contains('BookingDateAndTime('), reason: path);
        expect(code, isNot(contains('Icons.schedule_rounded')), reason: path);
      }
    },
  );
}
