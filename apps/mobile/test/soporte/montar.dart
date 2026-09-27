import 'dart:convert';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Un cliente de la API que responde siempre [codigo] con [cuerpo], sin red.
ClienteApi apiFalsa({int codigo = 201, String cuerpo = '{"id": 1}'}) =>
    ClienteApi(
      'http://api.falsa',
      cliente: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(cuerpo),
          codigo,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );

/// Monta [pantalla] con el tema y el idioma de la app, en un teléfono de [tamano].
Future<void> montar(
  WidgetTester tester,
  Widget pantalla, {
  required ThemeData tema,
  Size tamano = const Size(393, 852),
  double escalaTexto = 1,
}) async {
  tester.view.physicalSize = tamano * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: tema,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, hijo) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: hijo ?? const SizedBox.shrink(),
      ),
      home: pantalla,
    ),
  );
  await tester.pumpAndSettle();
}

/// Carga las fuentes del prototipo y los íconos: en los tests de widgets no vienen solas.
Future<void> cargarFuentes() async {
  const familias = {
    'Inter': [
      'assets/fuentes/Inter-Regular.ttf',
      'assets/fuentes/Inter-Medium.ttf',
      'assets/fuentes/Inter-SemiBold.ttf',
      'assets/fuentes/Inter-Bold.ttf',
    ],
    'Archivo': ['assets/fuentes/Archivo-ExtraBold.ttf'],
    'Archivo Black': ['assets/fuentes/ArchivoBlack-Regular.ttf'],
    'JetBrains Mono': ['assets/fuentes/JetBrainsMono-Regular.ttf'],
    'MaterialIcons': ['fonts/MaterialIcons-Regular.otf'],
  };
  for (final MapEntry(key: familia, value: archivos) in familias.entries) {
    final cargador = FontLoader(familia);
    for (final archivo in archivos) {
      cargador.addFont(rootBundle.load(archivo));
    }
    await cargador.load();
  }
}

/// Firebase sin red: [alIngresar] decide qué pasa con cada intento.
class CredencialesFalsas implements Credenciales {
  CredencialesFalsas({this.alIngresar, this.conCuenta = false});

  final Future<void> Function(String correo, String contrasena)? alIngresar;
  bool conCuenta;
  final intentos = <(String, String)>[];
  int salidas = 0;

  @override
  bool get hayCuenta => conCuenta;

  @override
  Future<void> ingresar(String correo, String contrasena) async {
    intentos.add((correo, contrasena));
    await alIngresar?.call(correo, contrasena);
    conCuenta = true;
  }

  @override
  Future<String?> token() async => conCuenta ? 'token-falso' : null;

  @override
  Future<void> salir() async {
    salidas++;
    conCuenta = false;
  }
}

/// El perfil que devuelve `GET /yo` en los tests.
String perfilJson({String rol = 'usuario'}) =>
    '{"nombre": "Nahuel", "apellido": "Mosse", '
    '"correo": "nahuel@correo.com", "rol": "$rol"}';
