import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'montar.dart';

const sedeHaedoJson =
    '{"id": 5, "nombre": "Sede Haedo", "direccion": "Av. Vergara 1850", '
    '"apertura": "08:00", "cierre": "23:00", "dias": [1,2,3,4,5,6,7], '
    '"canchas": 0}';
const sedeMoronJson =
    '{"id": 1, "nombre": "Sede Morón", "direccion": "Av. Rivadavia 19850", '
    '"apertura": "09:00", "cierre": "00:00", "dias": [1,2,3,4,5,6], '
    '"canchas": 1}';
const sedeCastelarJson =
    '{"id": 2, "nombre": "Sede Castelar", "direccion": "Av. Rivadavia 23500", '
    '"apertura": "08:00", "cierre": "22:00", "dias": [1,2,3,4,5,6,7], '
    '"canchas": 4}';

/// La app entera con la sesión de un administrador, abierta en [inicio].
Future<void> montarAdmin(
  WidgetTester tester, {
  required ClienteApi api,
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
      sesion: SesionFalsa(perfilAdmin),
      apariencia: Apariencia.enMemoria(oscuro: oscuro),
      inicio: inicio,
    ),
  );
  await tester.pumpAndSettle();
}

/// Abre el selector de [campo] y toca [opcion].
Future<void> elegir(WidgetTester tester, String campo, String opcion) async {
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
