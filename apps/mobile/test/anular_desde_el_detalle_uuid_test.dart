import 'dart:convert';

import 'package:clubnahuelmosse/admin/historial_reservas.dart';
import 'package:clubnahuelmosse/admin/pantalla_detalle_reserva.dart';
import 'package:clubnahuelmosse/espacios/espacios.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'soporte/admin.dart';
import 'soporte/montar.dart';

String _reserva({
  String estado = 'activa',
  bool anulable = true,
  String? motivo,
  String? anuladaEn,
  String? anuladaPor,
}) =>
    '{"id": "00000000-0000-7000-8000-000000000001", "espacio_id": "00000000-0000-7000-8000-000000000009", "sede_id": "00000000-0000-7000-8000-000000000001", "espacio":'
    ' "Moron_Rivadavia_19850_Futbol_F5_1", "deporte": "Futbol", "tipo": "F5", "sede":'
    ' "Sede Morón", "direccion": "Av. Rivadavia 19850", "inicio":'
    ' "2026-11-12T21:00:00-03:00", "fin": "2026-11-12T22:00:00-03:00", "total": 38000,'
    ' "estado": "$estado", "motivo": ${motivo == null ? 'null' : '"$motivo"'},'
    ' "usuario_id": "00000000-0000-7000-8000-000000000001", "usuario": "Nahuel Mosse",'
    ' "creado_en": "2026-11-02T18:42:00-03:00",'
    ' "cancelada_en": ${anuladaEn == null ? 'null' : '"$anuladaEn"'},'
    ' "cancelada_por_nombre": ${anuladaPor == null ? 'null' : '"$anuladaPor"'},'
    ' "espacio_de_baja": false, "anulable": $anulable}';

void main() {
  setUpAll(cargarFuentes);

  Future<void> abrirDetalle(
    WidgetTester tester,
    String reserva,
    List<http.Request> pedidos,
  ) async {
    final anulada = _reserva(
      estado: 'anulada',
      anulable: false,
      motivo: 'Lluvia',
      anuladaEn: '2026-11-12T18:30:00-03:00',
      anuladaPor: 'Ana Díaz',
    );
    final api = apiRutas({
      'POST /reservas/00000000-0000-7000-8000-000000000001/anular': (200, anulada),
    }, pedidos: pedidos);
    final sesion = SesionFalsa(perfilAdmin);
    final leida = ReservaHistorial.desdeJson(jsonDecode(reserva));
    expect(leida, isNotNull);
    await montar(
      tester,
      PantallaDetalleReserva(
        reserva: leida!,
        historial: HistorialDeReservas(api: api, sesion: sesion),
        sesion: sesion,
        espacios: Espacios(api: api, sesion: sesion),
        filtros: const FiltrosDeHistorial(),
        pendientes: FiltrosDePanelPendientes(),
      ),
      tema: temaOscuro,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  Iterable<http.Request> anulaciones(List<http.Request> pedidos) => pedidos
      .where((p) => p.method == 'POST' && p.url.path == '/reservas/00000000-0000-7000-8000-000000000001/anular');

  testWidgets(
    'el administrador anula una reserva desde el detalle del historial '
    '@REV-08-S8 @assumption:REV-08-ASM-01',
    (tester) async {
      final pedidos = <http.Request>[];
      await abrirDetalle(tester, _reserva(), pedidos);

      await tocar(tester, 'ANULAR RESERVA');
      expect(find.text('¿Anular esta reserva?'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tocar(tester, 'CONFIRMAR ANULACIÓN');

      expect(anulaciones(pedidos), hasLength(1));
      expect(
        jsonDecode(anulaciones(pedidos).single.body),
        containsPair('motivo', 'Lluvia'),
      );
      expect(find.text('Reserva anulada correctamente'), findsOneWidget);
    },
  );

  testWidgets(
    'el detalle de una reserva anulada dice quién la anuló, cuándo y por qué '
    '@REV-08-S8',
    (tester) async {
      await abrirDetalle(
        tester,
        _reserva(
          estado: 'anulada',
          anulable: false,
          motivo: 'Lluvia',
          anuladaEn: '2026-11-12T18:30:00-03:00',
          anuladaPor: 'Ana Díaz',
        ),
        [],
      );

      expect(find.text('Anulada por el administrador'), findsOneWidget);
      expect(find.textContaining('Por Ana Díaz'), findsOneWidget);
      expect(find.textContaining('12/11/2026 18:30'), findsOneWidget);
      expect(find.textContaining('Lluvia'), findsWidgets);
      expect(find.text('ANULAR RESERVA'), findsNothing);
    },
  );

  testWidgets(
    'volver sin confirmar la anulación deja la reserva igual @REV-08-S9',
    (tester) async {
      final pedidos = <http.Request>[];
      await abrirDetalle(tester, _reserva(), pedidos);

      await tocar(tester, 'ANULAR RESERVA');
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tocar(tester, 'VOLVER');

      expect(anulaciones(pedidos), isEmpty);
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsNothing);
    },
  );

  testWidgets(
    'cancelar el diálogo de anulación deja la reserva igual y la franja ocupada '
    '@REV-08-S9',
    (tester) async {
      final pedidos = <http.Request>[];
      await abrirDetalle(tester, _reserva(), pedidos);

      await tocar(tester, 'ANULAR RESERVA');
      await tester.enterText(find.byType(TextField).last, 'Lluvia');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(anulaciones(pedidos), isEmpty);
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsNothing);
    },
  );

  testWidgets(
    'tocar fuera del diálogo de anulación deja la reserva igual y vuelve al detalle '
    '@REV-08-S9',
    (tester) async {
      final pedidos = <http.Request>[];
      await abrirDetalle(tester, _reserva(), pedidos);

      await tocar(tester, 'ANULAR RESERVA');
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(anulaciones(pedidos), isEmpty);
      expect(find.text('¿Anular esta reserva?'), findsNothing);
      expect(find.text('ANULAR RESERVA'), findsOneWidget);
      expect(find.text('Anulada por el administrador'), findsNothing);
    },
  );
}
