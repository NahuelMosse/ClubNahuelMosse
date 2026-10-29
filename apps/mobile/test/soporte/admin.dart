import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'montar.dart';

const sedeHaedoJson =
    '{"id": "00000000-0000-7000-8000-000000000005", "name": "Sede Haedo", "address": "Av. Vergara 1850", '
    '"opens_at": "08:00", "closes_at": "23:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 0}';
const sedeMoronJson =
    '{"id": "00000000-0000-7000-8000-000000000001", "name": "Sede Morón", "address": "Av. Rivadavia 19850", '
    '"opens_at": "09:00", "closes_at": "00:00", "open_days": [1,2,3,4,5,6], '
    '"space_count": 1}';
const sedeCastelarJson =
    '{"id": "00000000-0000-7000-8000-000000000002", "name": "Sede Castelar", "address": "Av. Rivadavia 23500", '
    '"opens_at": "08:00", "closes_at": "22:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 4}';

/// La app entera con la sesión de un administrador, abierta en [inicio].
Future<void> montarAdmin(
  WidgetTester tester, {
  required ApiClient api,
  String inicio = '/admin/sedes',
  bool oscuro = true,
  Size tamano = const Size(393, 852),
}) async {
  tester.view.physicalSize = tamano * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: api,
      session: SesionFalsa(perfilAdmin),
      appearance: Appearance.inMemory(dark: oscuro),
      initialLocation: inicio,
    ),
  );
  await tester.pumpAndSettle();
}

/// Abre el selector de [campo] y toca [opcion].
Future<void> elegir(WidgetTester tester, String campo, String opcion) async {
  await tester.ensureVisible(find.bySemanticsLabel(campo));
  await tester.pumpAndSettle();
  await tester.tap(find.bySemanticsLabel(campo));
  await tester.pumpAndSettle();
  final boton = find.descendant(
    of: find.byType(Dialog),
    matching: find.text(opcion),
  );
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

const catalogoJson =
    '{"sports": ['
    '{"key": "Futbol", "name": "Fútbol", "kinds": ['
    '{"key": "F5", "name": "Fútbol 5"}, {"key": "F7", "name": "Fútbol 7"}]},'
    '{"key": "Tenis", "name": "Tenis", "kinds": ['
    '{"key": "PDL", "name": "Polvo de ladrillo"}]}]}';

const espacioF5Json =
    '{"id": "00000000-0000-7000-8000-000000000009", "name": "Moron_Rivadavia_19850_Futbol_F5_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
    '"venue": "Sede Morón", "sport": "Futbol", "kind": "F5", "number": 1, "covered": false, '
    '"lit": true, "price_per_hour": 38000}';
const espacioTenisJson =
    '{"id": "00000000-0000-7000-8000-000000000010", "name": "Moron_Rivadavia_19850_Tenis_PDL_1", "venue_id": "00000000-0000-7000-8000-000000000001", '
    '"venue": "Sede Morón", "sport": "Tenis", "kind": "PDL", "number": 1, "covered": false, '
    '"lit": false, "price_per_hour": 32000}';
const espacioCastelarJson =
    '{"id": "00000000-0000-7000-8000-000000000011", "name": "Castelar_Rivadavia_23500_Futbol_F7_1", "venue_id": "00000000-0000-7000-8000-000000000002", '
    '"venue": "Sede Castelar", "sport": "Futbol", "kind": "F7", "number": 1, "covered": true, '
    '"lit": true, "price_per_hour": 55000}';

/// Las respuestas de la API que usa el alta de espacio, con [alta] para el POST.
Map<String, (int, String)> rutasDeEspacios({
  (int, String) alta = (201, espacioF5Json),
  String sedes = '[$sedeMoronJson, $sedeCastelarJson]',
}) => {
  'GET /spaces/catalog': (200, catalogoJson),
  'GET /spaces': (200, '{"spaces": [$espacioF5Json]}'),
  'GET /spaces/name': (
    200,
    '{"name": "Moron_Rivadavia_19850_Futbol_F5_1", "number": 1}',
  ),
  'GET /venues': (200, '{"venues": $sedes}'),
  'POST /spaces': alta,
};
