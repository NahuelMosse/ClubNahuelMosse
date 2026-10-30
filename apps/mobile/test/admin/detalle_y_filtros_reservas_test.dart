import 'package:clubnahuelmosse/features/spaces/data/spaces_repository.dart';
import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/features/admin/data/booking_history_api.dart';
import 'package:clubnahuelmosse/features/admin/domain/history_filters.dart';
import 'package:clubnahuelmosse/features/admin/data/booking_history_json.dart';
import 'package:clubnahuelmosse/features/admin/domain/booking_history_entry.dart';
import 'package:clubnahuelmosse/features/admin/domain/pending_panel_filters.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_detail_screen.dart';
import 'package:clubnahuelmosse/features/admin/presentation/booking_filters_screen.dart';
import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../soporte/admin.dart';
import '../soporte/montar.dart';
import 'package:clubnahuelmosse/features/spaces/domain/space.dart';
import 'package:clubnahuelmosse/features/spaces/presentation/spaces.dart';

String _reserva({
  bool anulable = true,
  String estado = 'active',
  String aviso = '',
}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "space_id": "00000000-0000-7000-8000-000000000009", "venue_id": "00000000-0000-7000-8000-000000000001", "space":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol", "kind": "F5", "venue":'
    ' "Sede Morón", "address": "Av. Rivadavia 19850", "starts_at":'
    ' "2026-11-12T21:00:00-03:00", "ends_at": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "status": "$estado", "reason": ${estado == 'voided' ? '"lluvia"' : 'null'},'
    ' "user_id": "00000000-0000-7000-8000-000000000001", "user": "Nahuel Mosse",'
    ' "created_at": "2026-11-02T18:42:00-03:00",'
    ' "canceled_at": ${estado == 'voided' ? '"2026-11-03T10:00:00-03:00"' : 'null'},'
    ' "canceled_by_name": ${estado == 'voided' ? '"Ana Díaz"' : 'null'},'
    ' "space_deactivated": false, "voidable": $anulable$aviso}';

void main() {
  setUpAll(cargarFuentes);

  final sesion = SesionFalsa(perfilAdmin);

  Widget detalle(BookingHistoryEntry reserva, ApiClient api) =>
      BookingDetailScreen(
        booking: reserva,
        history: BookingHistory(api: api, sesion: sesion),
        session: sesion,
        spaces: Spaces(
          repository: SpacesRepository(api: api, session: sesion),
        ),
        filters: const HistoryFilters(),
        pending: PendingPanelFilters(),
      );

  BookingHistoryEntry leida(String json) {
    final r = parseBookingHistoryEntry(jsonDecode(json));
    if (r == null) fail('la reserva de prueba no se lee');
    return r;
  }

  group('detalle', () {
    testWidgets('muestra lo vigente en el servidor, con la línea de aviso', (
      tester,
    ) async {
      final api = apiRutas({
        'GET /bookings/all/00000000-0000-7000-8000-000000000001': (
          200,
          _reserva(
            anulable: false,
            estado: 'voided',
            aviso:
                ', "notice_delivery": "sent", "notice_at": "2026-11-03T10:00:05-03:00"',
          ),
        ),
        'GET /spaces/catalog': (200, catalogoJson),
      });
      await montar(tester, detalle(leida(_reserva()), api), tema: darkTheme);
      await tester.pumpAndSettle();

      expect(find.text('Notificación enviada al usuario'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.text('ANULAR RESERVA'), findsNothing);
    });

    testWidgets('nombra el deporte como el catálogo, con tilde', (
      tester,
    ) async {
      final api = apiRutas({'GET /spaces/catalog': (200, catalogoJson)});
      await montar(tester, detalle(leida(_reserva()), api), tema: darkTheme);
      await tester.pumpAndSettle();

      expect(find.text('Fútbol'), findsOneWidget);
      expect(find.text('Futbol'), findsNothing);
    });

    testWidgets('la flecha tiene nombre accesible', (tester) async {
      final semantica = tester.ensureSemantics();
      final api = apiRutas({'GET /spaces/catalog': (200, catalogoJson)});
      await montar(tester, detalle(leida(_reserva()), api), tema: darkTheme);
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(find.byTooltip('Volver'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('con la anulación en camino no se puede salir', (tester) async {
      final respuesta = Completer<http.Response>();
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) async {
          if (pedido.method == 'POST') return respuesta.future;
          return http.Response.bytes(
            utf8.encode(
              pedido.url.path == '/spaces/catalog' ? catalogoJson : '{}',
            ),
            pedido.url.path == '/spaces/catalog' ? 200 : 404,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      bool? resultado;
      await montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => detalle(leida(_reserva()), api),
                  ),
                );
              },
              child: const Text('ABRIR'),
            ),
          ),
        ),
        tema: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ANULAR RESERVA'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tester.ensureVisible(find.text('CONFIRMAR ANULACIÓN'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CONFIRMAR ANULACIÓN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip('Volver'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('VOLVER AL LISTADO'), warnIfMissed: false);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Detalle de reserva'), findsOneWidget);
      expect(resultado, isNull);

      respuesta.complete(
        http.Response.bytes(
          utf8.encode(_reserva(anulable: false, estado: 'voided')),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();

      expect(resultado, isTrue);
      expect(find.text('Detalle de reserva'), findsNothing);
    });
  });

  group('filtros', () {
    Future<void> abrir(WidgetTester tester) async {
      await montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openBookingFilters(
                context,
                filters: const HistoryFilters(),
                venues: const [],
                catalog: const Catalog([]),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
        tema: darkTheme,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();
    }

    bool aplicarHabilitado(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onTap != null;

    testWidgets('una fecha que no existe marca el error y bloquea APLICAR', (
      tester,
    ) async {
      await abrir(tester);
      expect(aplicarHabilitado(tester), isTrue);

      await tester.enterText(find.byType(TextField).first, '31022026');
      await tester.pumpAndSettle();

      expect(find.text('Fecha inválida'), findsOneWidget);
      expect(aplicarHabilitado(tester), isFalse);

      await tester.enterText(find.byType(TextField).first, '28022026');
      await tester.pumpAndSettle();

      expect(find.text('Fecha inválida'), findsNothing);
      expect(aplicarHabilitado(tester), isTrue);
    });

    testWidgets('la X tiene nombre accesible', (tester) async {
      final semantica = tester.ensureSemantics();
      await abrir(tester);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      semantica.dispose();
    });
  });
}
