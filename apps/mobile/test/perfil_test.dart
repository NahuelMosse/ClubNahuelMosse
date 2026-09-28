import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/usuarios/reglas_registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  late CredencialesFalsas credenciales;

  /// La app real en el perfil con una sesión iniciada. [yo] es lo que responde `GET /yo`
  /// al abrir el perfil; al iniciar sesión responde el perfil de siempre.
  Future<Apariencia> montarPerfil(
    WidgetTester tester, {
    (int, String) yo = (200, ''),
    Apariencia? apariencia,
  }) async {
    credenciales = CredencialesFalsas();
    var pedidos = 0;
    final api = ClienteApi(
      'http://api.falsa',
      cliente: MockClient((_) async {
        pedidos++;
        final (codigo, cuerpo) = pedidos == 1 || yo.$1 == 200
            ? (200, perfilJson())
            : yo;
        return http.Response.bytes(utf8.encode(cuerpo), codigo);
      }),
    );
    final sesion = Sesion(credenciales: credenciales, api: api);
    await sesion.iniciar('nahuel@correo.com', 'ClubNahuel1');
    final tema = apariencia ?? Apariencia.enMemoria();
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(api: api, sesion: sesion, apariencia: tema, inicio: '/perfil'),
    );
    await tester.pumpAndSettle();
    return tema;
  }

  testWidgets('muestra los datos con el DNI y la fecha para leer', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPerfil(tester);
    expect(find.text('DATOS PERSONALES'), findsOneWidget);
    expect(find.text('42.118.507'), findsOneWidget);
    expect(find.text('14/03/2000'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Correo: nahuel@correo.com. No se puede cambiar'),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('el selector de tema cambia la app y se guarda', (tester) async {
    final semantica = tester.ensureSemantics();
    SharedPreferences.setMockInitialValues({});
    final apariencia = await montarPerfil(
      tester,
      apariencia: await Apariencia.cargar(),
    );
    expect(apariencia.oscuro, isTrue);

    await tester.ensureVisible(find.bySemanticsLabel('Modo oscuro'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Modo oscuro'));
    await tester.pumpAndSettle();

    expect(apariencia.oscuro, isFalse);
    expect(
      Theme.of(tester.element(find.text('DATOS PERSONALES'))).brightness,
      Brightness.light,
    );
    final guardado = await SharedPreferences.getInstance();
    expect(guardado.getBool('modo_oscuro'), isFalse);
    semantica.dispose();
  });

  testWidgets(
    'si el servidor falla no muestra datos y «ACEPTAR» lleva al inicio',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await montarPerfil(tester, yo: (503, ''));
      expect(find.text('Error del servidor'), findsOneWidget);
      expect(find.text('DATOS PERSONALES'), findsNothing);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(find.text('RESERVÁ TU CANCHA'), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('con la sesión vencida no muestra datos y cierra la sesión', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPerfil(tester, yo: (401, '{}'));
    expect(find.text('Tu sesión expiró'), findsOneWidget);
    expect(find.text('DATOS PERSONALES'), findsNothing);
    await tester.tap(find.text('IR AL INICIO DE SESIÓN'));
    await tester.pumpAndSettle();
    expect(credenciales.salidas, 1);
    expect(find.text('INICIAR SESIÓN'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('«ELIMINAR CUENTA» pide confirmar y cancelar no hace nada', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montarPerfil(tester);
    await tester.ensureVisible(find.text('ELIMINAR CUENTA'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ELIMINAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
    await tester.tap(find.text('CANCELAR'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar tu cuenta?'), findsNothing);
    expect(credenciales.salidas, 0);
    semantica.dispose();
  });

  test('el DNI se lee con puntos de mil y la fecha con barras', () {
    expect(dniLegible('42118507'), '42.118.507');
    expect(dniLegible('4211850'), '4.211.850');
    expect(fechaLegible(DateTime(2000, 3, 4)), '04/03/2000');
  });

  test('un perfil sin DNI o fecha es un error del servidor', () async {
    final sesion = Sesion(
      credenciales: CredencialesFalsas(),
      api: apiRutas({
        'GET /yo': (
          200,
          '{"nombre": "N", "apellido": "M", "correo": "a@b.com", "rol": "usuario"}',
        ),
      }),
    );
    await expectLater(
      sesion.iniciar('a@b.com', 'Clave1234'),
      throwsA(isA<Exception>()),
    );
  });
}
