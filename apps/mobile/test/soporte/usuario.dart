import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/features/notifications/presentation/notification_center.dart';
import 'package:clubnahuelmosse/features/session/presentation/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin.dart';
import 'montar.dart';

const sedeMoronConDeportes =
    '{"id": "00000000-0000-7000-8000-000000000001", "name": "Sede Morón", "address": "Av. Rivadavia 19850", '
    '"opens_at": "08:00", "closes_at": "23:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 2, "sports": ["Futbol", "Tenis"]}';
const sedeHaedoSinCanchas =
    '{"id": "00000000-0000-7000-8000-000000000005", "name": "Sede Haedo", "address": "Av. Vergara 1850", '
    '"opens_at": "08:00", "closes_at": "22:00", "open_days": [1,2,3,4,5,6,7], '
    '"space_count": 0, "sports": []}';

/// La grilla del prototipo: jueves 12 de noviembre, 1 hora, seis horarios ocupados.
String grillaJson({
  String fecha = '2026-11-12',
  Set<int> ocupadas = const {9, 12, 16, 17, 21, 22},
  bool abre = true,
}) {
  String hora(int h) => '${h.toString().padLeft(2, '0')}:00';
  final franjas = [
    if (abre)
      for (var h = 8; h < 23; h++)
        '{"starts_at": "${hora(h)}", "ends_at": "${hora(h + 1)}", '
            '"available": ${!ocupadas.contains(h)}}',
  ];
  return '{"date": "$fecha", "today": "2026-11-12", "opens": $abre, '
      '"slots": [${franjas.join(', ')}], '
      '"unavailable": ${abre ? ocupadas.length : 0}}';
}

/// Las respuestas de la API para recorrer las sedes como usuario.
Map<String, (int, String)> rutasDeSedes({
  String sedes = '[$sedeMoronConDeportes, $sedeHaedoSinCanchas]',
  String espacios = '[$espacioF5Json, $espacioTenisJson]',
  String? grilla,
}) => {
  'GET /spaces/catalog': (200, catalogoJson),
  'GET /venues': (200, '{"venues": $sedes}'),
  'GET /spaces': (200, '{"spaces": $espacios}'),
  'GET /spaces/00000000-0000-7000-8000-000000000009/slots': (
    200,
    grilla ?? grillaJson(),
  ),
};

/// La app entera con la sesión de un usuario, abierta en [inicio].
Future<void> montarUsuario(
  WidgetTester tester, {
  required ApiClient api,
  String inicio = '/sedes',
  bool oscuro = true,
  Size tamano = const Size(393, 852),
  NotificationCenter Function(Session)? centro,
}) async {
  tester.view.physicalSize = tamano * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final sesion = SesionFalsa(perfilUsuario);
  await tester.pumpWidget(
    App(
      api: api,
      session: sesion,
      appearance: Appearance.inMemory(dark: oscuro),
      notificationCenter: centro?.call(sesion),
      initialLocation: inicio,
    ),
  );
  await tester.pumpAndSettle();
}
