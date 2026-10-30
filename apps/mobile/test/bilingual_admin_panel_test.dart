import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

const _english = [Locale('en', 'US')];

const _bookingJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "active", "reason": null, "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00", "canceled_at": null,'
    ' "canceled_by_name": null, "space_deactivated": false, "voidable": true}';

void main() {
  setUpAll(cargarFuentes);

  // A fresh tree per screen: pumping the same App keeps its router and its forms.
  Future<void> mount(
    WidgetTester tester, {
    required ApiClient api,
    String inicio = '/admin/sedes',
  }) async {
    await tester.pumpWidget(const SizedBox());
    await montarAdmin(tester, api: api, inicio: inicio);
  }

  testWidgets(
    'the admin panel, its lists and its forms show English @ENG-19-S1',
    (tester) async {
      tester.platformDispatcher.localesTestValue = _english;
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final semantics = tester.ensureSemantics();

      await mount(
        tester,
        inicio: '/admin',
        api: apiRutas({
          'GET /bookings/all': (
            200,
            '{"bookings": [$_bookingJson], "total": 1, "page": 1,'
                ' "per_page": 20, "counters": {"all": 1, "active": 1,'
                ' "completed": 0, "voided": 0}}',
          ),
          'GET /spaces/catalog': (200, catalogoJson),
        }),
      );
      expect(find.text('ADMIN PANEL'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.textContaining('1 BOOKING IN TOTAL'), findsOneWidget);
      expect(find.text('Active (1)'), findsOneWidget);
      expect(find.text('VOID BOOKING'), findsOneWidget);
      expect(find.text('Activas (1)'), findsNothing);

      await mount(
        tester,
        api: apiRutas({'GET /venues': (200, '{"venues": [$sedeMoronJson]}')}),
      );
      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('ADD VENUE'), findsOneWidget);
      expect(find.text('1 ACTIVE VENUE'), findsOneWidget);
      expect(find.bySemanticsLabel('Edit venue Sede Morón'), findsOneWidget);
      expect(find.text('AGREGAR SEDE'), findsNothing);

      await mount(
        tester,
        inicio: '/admin/espacios',
        api: apiRutas(rutasDeEspacios()),
      );
      expect(find.text('Spaces'), findsOneWidget);
      expect(find.text('ADD SPACE'), findsOneWidget);
      expect(find.textContaining('1 ACTIVE SPACE'), findsOneWidget);
      expect(find.text('ALTA ESPACIO'), findsNothing);

      await mount(
        tester,
        inicio: '/admin/sedes/nueva',
        api: apiRutas({'GET /venues': (200, '{"venues": []}')}),
      );
      expect(find.text('New venue'), findsOneWidget);
      expect(find.text('VENUE NAME'), findsOneWidget);
      expect(find.text('ADDRESS'), findsOneWidget);
      expect(find.text('OPENING TIME'), findsOneWidget);
      expect(find.text('CLOSING TIME'), findsOneWidget);
      expect(find.text('SAVE VENUE'), findsOneWidget);
      expect(find.text('GUARDAR SEDE'), findsNothing);

      await mount(
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
}
