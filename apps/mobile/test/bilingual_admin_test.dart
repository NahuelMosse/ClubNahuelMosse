import 'package:clubnahuelmosse/features/admin/domain/outside_hours.dart';
import 'package:clubnahuelmosse/features/admin/presentation/outside_hours_message.dart';
import 'package:clubnahuelmosse/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];
const _spanish = [Locale('es', 'AR')];

const _bookingJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "espacio_id": "00000000-0000-7000-8000-000000000009", "sede_id": "00000000-0000-7000-8000-000000000001", "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "activa", "motivo": null, "usuario_id": "00000000-0000-7000-8000-000000000001", "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00", "cancelada_en": null,'
    ' "cancelada_por_nombre": null, "espacio_de_baja": false}';

void main() {
  setUpAll(cargarFuentes);

  void device(WidgetTester tester, List<Locale> locales) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the admin panel, its lists and its forms show English @ENG-19-S1',
    (tester) async {
      device(tester, _english);
      final semantics = tester.ensureSemantics();

      await montarAdmin(
        tester,
        inicio: '/admin',
        api: apiRutas({
          'GET /reservas/todas': (
            200,
            '{"reservas": [$_bookingJson], "total": 1, "pagina": 1,'
                ' "por_pagina": 20, "contadores": {"todas": 1, "activas": 1,'
                ' "completadas": 0, "anuladas": 0}}',
          ),
          'GET /espacios/catalogo': (200, catalogoJson),
        }),
      );
      expect(find.text('ADMIN PANEL'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.textContaining('1 BOOKING IN TOTAL'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('VOID BOOKING'), findsOneWidget);
      expect(find.text('Activas (1)'), findsNothing);

      await montarAdmin(
        tester,
        api: apiRutas({'GET /sedes': (200, '{"sedes": [$sedeMoronJson]}')}),
      );
      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('ADD VENUE'), findsOneWidget);
      expect(find.text('1 ACTIVE VENUE'), findsOneWidget);
      expect(find.bySemanticsLabel('Edit venue Sede Morón'), findsOneWidget);
      expect(find.text('AGREGAR SEDE'), findsNothing);

      await montarAdmin(
        tester,
        inicio: '/admin/espacios',
        api: apiRutas(rutasDeEspacios()),
      );
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.text('ADD SPACE'), findsOneWidget);
      expect(find.text('1 ACTIVE SPACE'), findsOneWidget);
      expect(find.text('ALTA ESPACIO'), findsNothing);

      await montarAdmin(
        tester,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
      );
      expect(find.text('New venue'), findsOneWidget);
      expect(find.text('VENUE NAME'), findsOneWidget);
      expect(find.text('ADDRESS'), findsOneWidget);
      expect(find.text('OPENING TIME'), findsOneWidget);
      expect(find.text('CLOSING TIME'), findsOneWidget);
      expect(find.text('SAVE VENUE'), findsOneWidget);
      expect(find.text('GUARDAR SEDE'), findsNothing);

      await montarAdmin(
        tester,
        inicio: '/admin/espacios/nuevo',
        api: apiRutas(rutasDeEspacios()),
      );
      expect(find.text('New sports space'), findsOneWidget);
      expect(find.text('SAVE SPACE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('PRICE PER HOUR'), findsOneWidget);
      expect(find.text('GUARDAR ESPACIO'), findsNothing);
      semantics.dispose();
    },
  );

  testWidgets(
    'the admin form validations the domain decides show in English and in Spanish @ENG-19-ASM-05',
    (tester) async {
      final semantics = tester.ensureSemantics();
      for (final (locales, save, messages, address) in [
        (
          _english,
          'SAVE VENUE',
          [
            'The name is required',
            'The address is required',
            'The opening time is required',
            'The closing time is required',
          ],
          'Write the street and number',
        ),
        (
          _spanish,
          'GUARDAR SEDE',
          [
            'El nombre es obligatorio',
            'La dirección es obligatoria',
            'El horario de apertura es obligatorio',
            'El horario de cierre es obligatorio',
          ],
          'Escribí la calle y la altura',
        ),
      ]) {
        device(tester, locales);
        await montarAdmin(
          tester,
          inicio: '/admin/sedes/nueva',
          api: apiRutas({'GET /sedes': (200, '{"sedes": []}')}),
        );
        await tap(tester, save);
        for (final message in messages) {
          expect(find.text(message), findsOneWidget, reason: message);
        }

        await tester.enterText(find.byType(EditableText).at(1), 'Calle');
        await tester.pumpAndSettle();
        await tap(tester, save);
        expect(find.text(address), findsOneWidget, reason: address);
      }
      semantics.dispose();
    },
  );

  test(
    'the outside-hours notice agrees in singular and in plural (termina/terminan, cae/caen, se mantiene/se mantienen and their English forms) @ENG-19-ASM-06',
    () {
      String message(String language, int count, List<OutsideReason> reasons) =>
          outsideHoursMessage(
            lookupAppLocalizations(Locale(language)),
            OutsideHours(
              count: count,
              venueName: 'Sede Morón',
              reasons: reasons,
              opensHour: '09:00',
              closesHour: '22:00',
            ),
          );
      const starts = [OutsideReason.startsBefore];
      const ends = [OutsideReason.endsAfter];
      const day = [OutsideReason.closedDay];
      const several = [OutsideReason.startsBefore, OutsideReason.endsAfter];
      const keepEs =
          'en su horario original: el cambio rige para las reservas nuevas.';

      expect(
        message('es', 1, starts),
        '1 reserva futura de Sede Morón empieza antes de las 09:00. Si guardás, se mantiene $keepEs',
      );
      expect(
        message('es', 3, starts),
        '3 reservas futuras de Sede Morón empiezan antes de las 09:00. Si guardás, se mantienen $keepEs',
      );
      expect(
        message('es', 1, ends),
        '1 reserva futura de Sede Morón termina después de las 22:00. Si guardás, se mantiene $keepEs',
      );
      expect(
        message('es', 2, ends),
        '2 reservas futuras de Sede Morón terminan después de las 22:00. Si guardás, se mantienen $keepEs',
      );
      expect(
        message('es', 1, day),
        '1 reserva futura de Sede Morón cae en un día que la sede deja de abrir. Si guardás, se mantiene $keepEs',
      );
      expect(
        message('es', 2, day),
        '2 reservas futuras de Sede Morón caen en un día que la sede deja de abrir. Si guardás, se mantienen $keepEs',
      );
      expect(
        message('es', 1, several),
        '1 reserva futura de Sede Morón queda fuera del horario nuevo. Si guardás, se mantiene $keepEs',
      );
      expect(
        message('es', 4, several),
        '4 reservas futuras de Sede Morón quedan fuera del horario nuevo. Si guardás, se mantienen $keepEs',
      );

      const keepMany =
          'at their original time: the change applies to new bookings.';
      const keepOne =
          'at its original time: the change applies to new bookings.';
      expect(
        message('en', 1, starts),
        '1 future booking at Sede Morón starts before 09:00. If you save, it stays $keepOne',
      );
      expect(
        message('en', 3, ends),
        '3 future bookings at Sede Morón end after 22:00. If you save, they stay $keepMany',
      );
      expect(
        message('en', 1, ends),
        '1 future booking at Sede Morón ends after 22:00. If you save, it stays $keepOne',
      );
      expect(
        message('en', 2, day),
        '2 future bookings at Sede Morón fall on a day the venue stops opening. If you save, they stay $keepMany',
      );
      expect(
        message('en', 1, day),
        '1 future booking at Sede Morón falls on a day the venue stops opening. If you save, it stays $keepOne',
      );
      expect(
        message('en', 1, several),
        '1 future booking at Sede Morón falls outside the new schedule. If you save, it stays $keepOne',
      );
      expect(
        message('en', 2, several),
        '2 future bookings at Sede Morón fall outside the new schedule. If you save, they stay $keepMany',
      );
    },
  );
}
