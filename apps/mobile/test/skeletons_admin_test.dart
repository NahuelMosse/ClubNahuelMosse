import 'dart:async';
import 'dart:convert';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/button.dart';
import 'package:clubnahuelmosse/common/selector.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_booking_card.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_space_card.dart';
import 'package:clubnahuelmosse/features/admin/presentation/admin_venue_card.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:clubnahuelmosse/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';
import 'soporte/held_api.dart';
import 'soporte/montar.dart';

const _frame = ValueKey('skeleton-card');

String _reserva(int n) {
  final start = DateTime.now().toUtc().add(const Duration(days: 30));
  final end = start.add(const Duration(hours: 1));
  return '{"id": "00000000-0000-7000-8000-${n.toString().padLeft(12, '0')}",'
      ' "space_id": "00000000-0000-7000-8000-000000000009",'
      ' "venue_id": "00000000-0000-7000-8000-000000000001",'
      ' "space": "Moron_Rivadavia_19850_Futbol_F5_1", "sport": "Futbol",'
      ' "kind": "F5", "venue": "Sede Morón", "address": "Av. Rivadavia 19850",'
      ' "starts_at": "${start.toIso8601String()}", "ends_at": "${end.toIso8601String()}",'
      ' "total": 38000, "status": "active", "reason": null,'
      ' "user_id": "00000000-0000-7000-8000-000000000001",'
      ' "user": "Socio $n", "created_at": "2026-11-02T18:42:00-03:00",'
      ' "canceled_at": null, "canceled_by_name": null,'
      ' "space_deactivated": false}';
}

String _pagina(Iterable<int> ids, int numero) =>
    '{"bookings": [${ids.map(_reserva).join(',')}], "total": 40,'
    ' "page": $numero, "per_page": 20, "counters": {"all": 40,'
    ' "active": 40, "completed": 0, "voided": 0}}';

Future<void> _abrir(WidgetTester tester, ApiClient api, String inicio) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: api,
      session: SesionFalsa(perfilAdmin),
      appearance: Appearance.inMemory(dark: true),
      initialLocation: inicio,
    ),
  );
  await tester.pump();
  await tester.pump();
}

Rect _rect(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> _cardShape(
  WidgetTester tester, {
  required String inicio,
  required Type card,
}) async {
  final held = HeldApi({
    ...rutasDeEspacios(),
    'GET /venues': (200, '{"venues": [$sedeMoronJson]}'),
  });
  await _abrir(tester, held.client, inicio);
  expect(find.byType(CircularProgressIndicator), findsNothing);
  final frame = find.byKey(_frame).first;
  final frameRect = _rect(tester, frame);
  expect(skeletonRects(tester, within: frame), hasLength(greaterThan(2)));

  held.release();
  await tester.pumpAndSettle();
  expectSameBox(
    frameRect,
    _rect(tester, find.byType(card).first),
    reason: 'la tarjeta de carga ocupa el lugar de la real',
  );
}

void main() {
  setUpAll(cargarFuentes);

  testWidgets(
    'Espacios del admin carga con la forma de su tarjeta @VIS-03-S1',
    (tester) =>
        _cardShape(tester, inicio: '/admin/espacios', card: AdminSpaceCard),
  );

  testWidgets(
    'Sedes del admin carga con la forma de su tarjeta @VIS-03-S1',
    (tester) =>
        _cardShape(tester, inicio: '/admin/sedes', card: AdminVenueCard),
  );

  testWidgets(
    'la página siguiente del historial es un bloque con la forma de una reserva '
    '@VIS-03-S1 @assumption:VIS-03-ASM-04',
    (tester) async {
      final segunda = Completer<http.Response>();
      final api = ApiClient(
        'http://api.falsa',
        cliente: MockClient((pedido) {
          final cabeceras = {'content-type': 'application/json; charset=utf-8'};
          if (pedido.url.path == '/bookings/all') {
            if (pedido.url.queryParameters['page'] == '2') {
              return segunda.future;
            }
            return Future.value(
              http.Response.bytes(
                utf8.encode(_pagina(List.generate(20, (i) => i + 1), 1)),
                200,
                headers: cabeceras,
              ),
            );
          }
          return Future.value(
            http.Response.bytes(
              utf8.encode(catalogoJson),
              pedido.url.path == '/spaces/catalog' ? 200 : 404,
              headers: cabeceras,
            ),
          );
        }),
      );
      await _abrir(tester, api, '/admin');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      final real = _rect(tester, find.byType(AdminBookingCard).first);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -20000));
      await tester.pump();
      await tester.pump();

      final block = find.byType(Skeleton, skipOffstage: false);
      expect(block, findsOneWidget);
      final skeleton = tester.widget<Skeleton>(block);
      expect(skeleton.radius, Spacing.radiusLg);
      expect(skeleton.height, moreOrLessEquals(real.height, epsilon: 8));

      segunda.complete(
        http.Response.bytes(
          utf8.encode(_pagina([21], 2)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'el historial del panel carga con su texto de carga y filas skeleton '
    '@VIS-03-S2 @assumption:VIS-03-ASM-03',
    (tester) async {
      final held = HeldApi({
        'GET /bookings/all': (200, _pagina([1, 2], 1)),
        'GET /spaces/catalog': (200, catalogoJson),
      });
      await _abrir(tester, held.client, '/admin');
      expect(find.text('Cargando reservas…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final frames = find.byKey(_frame);
      expect(frames, findsWidgets);
      final first = _rect(tester, frames.first);
      expect(skeletonRects(tester, within: frames.first), isNotEmpty);

      held.release();
      await tester.pumpAndSettle();
      final real = _rect(tester, find.byType(AdminBookingCard).first);
      expect(first.left, moreOrLessEquals(real.left, epsilon: 1));
      expect(first.right, moreOrLessEquals(real.right, epsilon: 1));
      expect(first.height, moreOrLessEquals(real.height, epsilon: 8));
    },
  );

  testWidgets(
    'Alta de espacio carga con la forma de su formulario, no un spinner '
    '@VIS-03-S2',
    (tester) async {
      final held = HeldApi(rutasDeEspacios());
      await _abrir(tester, held.client, '/admin/espacios/nuevo');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Nuevo espacio'), findsOneWidget);
      expect(find.text('Nuevo espacio deportivo'), findsOneWidget);
      final blocks = skeletonRects(tester);
      expect(blocks.length, greaterThanOrEqualTo(5));

      held.release();
      await tester.pumpAndSettle();
      final fields = find.byType(SelectorField);
      expect(fields, findsNWidgets(5));
      for (var i = 0; i < 5; i++) {
        expectSameBox(
          blocks[i],
          _rect(tester, fields.at(i)),
          reason: 'selector $i',
        );
      }
    },
  );

  testWidgets(
    'las pantallas que reciben sus datos cargados no muestran skeleton y los '
    'spinners de botones siguen @assumption:VIS-03-ASM-02',
    (tester) async {
      final held = HeldApi(rutasDeEspacios());
      await _abrir(tester, held.client, '/admin/espacios/nuevo');
      held.release();
      await tester.pumpAndSettle();
      expect(find.byType(Skeleton), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: PrimaryButton(label: 'GUARDAR', loading: true, onTap: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Skeleton), findsNothing);
    },
  );
}
