import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/history_filters.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte/montar.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';

String reservaJson({
  String estado = 'voided',
  String? envio,
  String? envioEn,
}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$estado", "reason": "mantenimiento de la cancha",'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00",'
    ' "canceled_at": "2026-11-03T10:00:00-03:00",'
    ' "canceled_by_name": "Ana Díaz", "space_deactivated": false,'
    ' "voidable": false, "notice_delivery": ${envio == null ? 'null' : '"$envio"'},'
    ' "notice_at": ${envioEn == null ? 'null' : '"$envioEn"'}}';

void main() {
  Future<void> abrir(
    WidgetTester tester,
    String json, {
    Size tamano = const Size(360, 800),
    double escala = 1,
  }) async {
    final reserva = parseBookingHistoryEntry(jsonDecode(json));
    if (reserva == null) fail('la reserva de prueba no se lee');
    final sesion = SesionFalsa(perfilAdmin);
    final api = apiRutas({});
    await montar(
      tester,
      BookingDetailScreen(
        booking: reserva,
        history: BookingHistory(api: api, sesion: sesion),
        session: sesion,
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: sesion),
        ),
        filters: const HistoryFilters(),
        pending: PendingPanelFilters(),
      ),
      tema: darkTheme,
      tamano: tamano,
      escalaTexto: escala,
    );
  }

  group('la trazabilidad del detalle muestra cómo salió el aviso', () {
    testWidgets('enviado: dice que se envió y cuándo', (tester) async {
      await abrir(
        tester,
        reservaJson(envio: 'sent', envioEn: '2026-11-03T10:00:05-03:00'),
      );

      expect(find.text('Notificación enviada al usuario'), findsOneWidget);
      expect(find.text('03/11/2026 10:00'), findsWidgets);
    });

    for (final envio in ['no_permission', 'no_channel', 'failed']) {
      testWidgets('$envio: queda en el centro y el push no salió', (
        tester,
      ) async {
        await abrir(
          tester,
          reservaJson(envio: envio, envioEn: '2026-11-03T10:00:05-03:00'),
        );

        expect(find.text('Aviso en el centro del usuario'), findsOneWidget);
        expect(find.text('El push no salió'), findsOneWidget);
        expect(find.text('Notificación enviada al usuario'), findsNothing);
      });
    }

    testWidgets('pendiente o sin aviso: no figura', (tester) async {
      await abrir(tester, reservaJson());

      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('Notificación enviada al usuario'), findsNothing);
      expect(find.text('Aviso en el centro del usuario'), findsNothing);
    });

    for (final (ancho, alto) in [(360.0, 800.0), (430.0, 932.0)]) {
      testWidgets('al 200 % en $ancho de ancho no se corta', (tester) async {
        await abrir(
          tester,
          reservaJson(envio: 'no_channel', envioEn: '2026-11-03T10:00:05-03:00'),
          tamano: Size(ancho, alto),
          escala: 2,
        );
        await tester.ensureVisible(find.text('Aviso en el centro del usuario'));

        expect(find.text('El push no salió'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
