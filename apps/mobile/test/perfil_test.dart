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
  final ediciones = <String>[];

  /// La app real en el perfil con una sesión iniciada. [yo] es lo que responde `GET /yo`
  /// al abrir el perfil; al iniciar sesión responde el perfil de siempre.
  Future<Apariencia> montarPerfil(
    WidgetTester tester, {
    (int, String) yo = (200, ''),
    (int, String) edicion = (200, ''),
    Apariencia? apariencia,
  }) async {
    credenciales = CredencialesFalsas();
    ediciones.clear();
    var consultas = 0;
    final api = ClienteApi(
      'http://api.falsa',
      cliente: MockClient((pedido) async {
        if (pedido.method == 'PUT') {
          ediciones.add(pedido.body);
          final (codigo, cuerpo) = edicion;
          return http.Response.bytes(utf8.encode(cuerpo), codigo);
        }
        consultas++;
        final (codigo, cuerpo) = consultas == 1 || yo.$1 == 200
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

  group('editar los datos personales', () {
    Future<void> editar(WidgetTester tester) async {
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
    }

    Future<void> guardar(WidgetTester tester) async {
      await tester.ensureVisible(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
    }

    testWidgets('guarda los datos normalizados y vuelve a lectura', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montarPerfil(
        tester,
        edicion: (
          200,
          '{"nombre": "Agustín", "apellido": "Mosse", "correo": "nahuel@correo.com", '
              '"rol": "usuario", "dni": "42118507", "fecha_nacimiento": "2000-03-14"}',
        ),
      );
      await editar(tester);
      await tester.enterText(find.bySemanticsLabel('Nombre'), '  Agustín ');
      await guardar(tester);

      expect(ediciones, [
        '{"nombre":"Agustín","apellido":"Mosse","dni":"42118507",'
            '"fecha_nacimiento":"2000-03-14"}',
      ]);
      expect(find.text('GUARDAR'), findsNothing);
      expect(find.text('Agustín Mosse'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets(
      'marca los datos inválidos con el mensaje del prototipo y no manda nada',
      (tester) async {
        final semantica = tester.ensureSemantics();
        await montarPerfil(tester);
        await editar(tester);
        await tester.enterText(find.bySemanticsLabel('DNI'), '42118');
        await tester.enterText(
          find.bySemanticsLabel('Fecha de nacimiento'),
          '32132000',
        );
        await tester.enterText(find.bySemanticsLabel('Apellido'), '');
        await guardar(tester);

        expect(
          find.text('El formato de los datos no es válido'),
          findsNWidgets(3),
        );
        expect(ediciones, isEmpty);

        // Al corregir un campo se va su error y quedan los demás.
        await tester.enterText(find.bySemanticsLabel('DNI'), '42118507');
        await tester.pump();
        expect(
          find.text('El formato de los datos no es válido'),
          findsNWidgets(2),
        );
        semantica.dispose();
      },
    );

    testWidgets('un DNI de otra cuenta se marca con su propio mensaje', (
      tester,
    ) async {
      // Verifica CU-06-SUP-02.
      final semantica = tester.ensureSemantics();
      await montarPerfil(
        tester,
        edicion: (409, '{"errores": {"dni": "Este DNI ya está registrado"}}'),
      );
      await editar(tester);
      await tester.enterText(find.bySemanticsLabel('DNI'), '30111222');
      await guardar(tester);
      expect(find.text('Este DNI ya está registrado'), findsOneWidget);
      expect(find.text('GUARDAR'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('si el servidor falla conserva lo escrito', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarPerfil(tester, edicion: (500, ''));
      await editar(tester);
      await tester.enterText(find.bySemanticsLabel('Nombre'), 'Agustín');
      await guardar(tester);
      expect(find.text('Error del servidor'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      final nombre = tester.widget<TextField>(
        find.descendant(
          of: find.bySemanticsLabel('Nombre'),
          matching: find.byType(TextField),
        ),
      );
      expect(nombre.controller?.text, 'Agustín');
      semantica.dispose();
    });
  });

  testWidgets(
    'el calendario abre aunque la fecha escrita sea de hoy o futura',
    (tester) async {
      final semantica = tester.ensureSemantics();
      await montarPerfil(tester);
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.bySemanticsLabel('Fecha de nacimiento'),
        '01012999',
      );
      await tester.tap(find.byTooltip('Elegir la fecha en el calendario'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      semantica.dispose();
    },
  );

  testWidgets('el Home y el avatar siguen al perfil cuando cambia', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    final sesion = Sesion(
      credenciales: CredencialesFalsas(),
      api: apiRutas({
        'GET /yo': (200, perfilJson()),
        'PUT /yo': (
          200,
          '{"nombre": "Agustín", "apellido": "Paz", "correo": "nahuel@correo.com", '
              '"rol": "usuario", "dni": "42118507", "fecha_nacimiento": "2000-03-14"}',
        ),
      }),
    );
    await sesion.iniciar('a@b.com', 'Clave1234');
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: apiFalsa(),
        sesion: sesion,
        apariencia: Apariencia.enMemoria(),
        inicio: '/inicio',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nahuel'), findsOneWidget);

    await sesion.editarPerfil(
      nombre: 'Agustín',
      apellido: 'Paz',
      dni: '42118507',
      fechaNacimiento: '2000-03-14',
    );
    await tester.pumpAndSettle();
    expect(find.text('Agustín'), findsOneWidget);
    expect(find.text('AP'), findsOneWidget);
    semantica.dispose();
  });
}
