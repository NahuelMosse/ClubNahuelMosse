import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

/// Una API que nunca contesta: la pantalla se queda cargando.
ApiClient _apiColgada() => ApiClient(
  'http://api.falsa',
  cliente: MockClient((_) => Completer<http.Response>().future),
);

/// Monta la app con la API colgada y, al terminar, la desmonta y deja pasar
/// el límite de espera para que no quede el Timer del cliente pendiente.
Future<void> _cargando(
  WidgetTester tester, {
  required String inicio,
  required bool admin,
}) async {
  tester.view.physicalSize = const Size(393, 852) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    App(
      api: _apiColgada(),
      session: SesionFalsa(admin ? perfilAdmin : perfilUsuario),
      appearance: Appearance.inMemory(dark: true),
      initialLocation: inicio,
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  group('esqueletos de carga con la API colgada', () {
    for (final (ruta, admin) in [
      ('/sedes', false),
      ('/reservas', false),
      ('/inicio', false),
      ('/admin/sedes', true),
    ]) {
      testWidgets(
        'cada pantalla que carga muestra skeletons con la forma de su contenido y no un spinner @VIS-02-S1 @assumption:VIS-02-ASM-02 $ruta',
        (tester) async {
          await _cargando(tester, inicio: ruta, admin: admin);
          expect(find.byType(Skeleton), findsWidgets);
          expect(find.byType(CircularProgressIndicator), findsNothing);

          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(minutes: 2));
        },
      );
    }
  });
}
