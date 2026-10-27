import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/notificaciones/centro.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin.dart';
import 'montar.dart';

const sedeMoronConDeportes =
    '{"id": "00000000-0000-7000-8000-000000000001", "nombre": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
    '"apertura": "08:00", "cierre": "23:00", "dias": [1,2,3,4,5,6,7], '
    '"canchas": 2, "deportes": ["Futbol", "Tenis"]}';
const sedeHaedoSinCanchas =
    '{"id": "00000000-0000-7000-8000-000000000005", "nombre": "Sede Haedo", "direccion": "Av. Vergara 1850", '
    '"apertura": "08:00", "cierre": "22:00", "dias": [1,2,3,4,5,6,7], '
    '"canchas": 0, "deportes": []}';

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
        '{"inicio": "${hora(h)}", "fin": "${hora(h + 1)}", '
            '"disponible": ${!ocupadas.contains(h)}}',
  ];
  return '{"fecha": "$fecha", "hoy": "2026-11-12", "abre": $abre, '
      '"franjas": [${franjas.join(', ')}], '
      '"no_disponibles": ${abre ? ocupadas.length : 0}}';
}

/// Las respuestas de la API para recorrer las sedes como usuario.
Map<String, (int, String)> rutasDeSedes({
  String sedes = '[$sedeMoronConDeportes, $sedeHaedoSinCanchas]',
  String espacios = '[$espacioF5Json, $espacioTenisJson]',
  String? grilla,
}) => {
  'GET /espacios/catalogo': (200, catalogoJson),
  'GET /sedes': (200, '{"sedes": $sedes}'),
  'GET /espacios': (200, '{"espacios": $espacios}'),
  'GET /espacios/00000000-0000-7000-8000-000000000009/horarios': (200, grilla ?? grillaJson()),
};

/// La app entera con la sesión de un usuario, abierta en [inicio].
Future<void> montarUsuario(
  WidgetTester tester, {
  required ClienteApi api,
  String inicio = '/sedes',
  bool oscuro = true,
  Size tamano = const Size(393, 852),
  CentroDeNotificaciones Function(Sesion)? centro,
}) async {
  tester.view.physicalSize = tamano * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final sesion = SesionFalsa(perfilUsuario);
  await tester.pumpWidget(
    App(
      api: api,
      sesion: sesion,
      apariencia: Apariencia.enMemoria(oscuro: oscuro),
      centro: centro?.call(sesion),
      inicio: inicio,
    ),
  );
  await tester.pumpAndSettle();
}
