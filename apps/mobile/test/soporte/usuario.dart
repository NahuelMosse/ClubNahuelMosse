import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'admin.dart';
import 'montar.dart';

const sedeMoronConDeportes =
    '{"id": 1, "nombre": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
    '"apertura": "08:00", "cierre": "23:00", "dias": [1,2,3,4,5,6,7], '
    '"canchas": 2, "deportes": ["Futbol", "Tenis"]}';
const sedeHaedoSinCanchas =
    '{"id": 5, "nombre": "Sede Haedo", "direccion": "Av. Vergara 1850", '
    '"apertura": "08:00", "cierre": "22:00", "dias": [1,2,3,4,5,6,7], '
    '"canchas": 0, "deportes": []}';

/// Las respuestas de la API para recorrer las sedes como usuario.
Map<String, (int, String)> rutasDeSedes({
  String sedes = '[$sedeMoronConDeportes, $sedeHaedoSinCanchas]',
  String espacios = '[$espacioF5Json, $espacioTenisJson]',
}) => {
  'GET /espacios/catalogo': (200, catalogoJson),
  'GET /sedes': (200, '{"sedes": $sedes}'),
  'GET /espacios': (200, '{"espacios": $espacios}'),
};

/// La app entera con la sesión de un usuario, abierta en [inicio].
Future<void> montarUsuario(
  WidgetTester tester, {
  required ClienteApi api,
  String inicio = '/sedes',
  bool oscuro = true,
  Size tamano = const Size(393, 852),
}) async {
  tester.view.physicalSize = tamano * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: api,
      sesion: SesionFalsa(perfilUsuario),
      apariencia: Apariencia.enMemoria(oscuro: oscuro),
      inicio: inicio,
    ),
  );
  await tester.pumpAndSettle();
}
