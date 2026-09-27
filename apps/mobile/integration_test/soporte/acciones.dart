import 'dart:convert';
import 'dart:io';

import 'package:clubnahuelmosse/configuracion.dart';
import 'package:clubnahuelmosse/main.dart' as app;
import 'package:clubnahuelmosse/sesion/firebase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Un valor que sólo usa este test: los escenarios afirman sobre datos propios.
String unico() => DateTime.now().microsecondsSinceEpoch.toString();

/// DNI de 8 dígitos derivado de [s], para que dos tests no choquen.
String dniDe(String s) =>
    (10000000 + int.parse(s.substring(s.length - 7))).toString();

/// La cuenta de administrador que `scripts/e2e.sh` siembra en la base de la corrida.
const correoAdmin = String.fromEnvironment('ADMIN_CORREO');
const contrasenaAdmin = String.fromEnvironment('ADMIN_CONTRASENA');

/// Un emulador de Firebase Auth y una API donde no escucha nadie: la app sin red.
const sinRed = '127.0.0.1:9';
const apiSinRed = 'http://127.0.0.1:9';

/// Arranca la app real, contra la API y el emulador de Firebase de la corrida.
///
/// [apiUrl] y [authEmulador] reemplazan los de la corrida para simular fallas.
Future<void> abrirApp(
  WidgetTester tester, {
  String? apiUrl,
  String? authEmulador,
}) async {
  final configuracion = Configuracion.desdeEntorno().con(
    apiUrl: apiUrl,
    authEmulador: authEmulador,
  );
  // Cada escenario arranca sin la sesión que haya dejado abierta el anterior.
  await (await iniciarFirebase(configuracion)).signOut();
  await app.arrancar(configuracion);
  await tester.pumpAndSettle();
}

/// Vuelve a arrancar la app como al reabrirla: con la sesión que haya quedado guardada.
Future<void> reabrirApp(WidgetTester tester) async {
  await app.arrancar(Configuracion.desdeEntorno());
  await tester.pumpAndSettle();
}

/// Crea una cuenta, abre la app e inicia sesión con ella hasta llegar al Home.
Future<void> entrarComoUsuario(
  WidgetTester tester, {
  required String correo,
  String contrasena = 'ClubNahuel1',
  String nombre = 'Nahuel',
  String? apiUrl,
}) async {
  await crearCuenta(correo: correo, contrasena: contrasena, nombre: nombre);
  await abrirApp(tester, apiUrl: apiUrl);
  await escribir(tester, 'Correo', correo);
  await escribir(tester, 'Contraseña', contrasena);
  await tocar(tester, 'INICIAR SESIÓN');
  await esperarA(tester, find.text('RESERVÁ TU CANCHA'));
}

/// Registra una cuenta por la API, como si la persona ya se hubiera registrado.
Future<void> crearCuenta({
  required String correo,
  required String contrasena,
  String nombre = 'Nahuel',
}) async {
  final r = await http.post(
    Uri.parse('${Configuracion.desdeEntorno().apiUrl}/registro'),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({
      'nombre': nombre,
      'apellido': 'Mosse',
      'dni': dniDe(unico()),
      'fecha_nacimiento': '2000-03-14',
      'correo': correo,
      'contrasena': contrasena,
    }),
  );
  if (r.statusCode != 201) {
    throw StateError('no se pudo crear la cuenta de prueba: ${r.statusCode}');
  }
}

/// Una API que responde 500 a todo, en el mismo dispositivo que la app.
Future<String> apiQueFalla() async {
  final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  servidor.listen((pedido) {
    pedido.response.statusCode = HttpStatus.internalServerError;
    pedido.response.close();
  });
  addTearDown(() => servidor.close(force: true));
  return 'http://127.0.0.1:${servidor.port}';
}

/// Espera a que [finder] aparezca: la red no avisa cuándo termina.
Future<void> esperarA(
  WidgetTester tester,
  Finder finder, {
  Duration limite = const Duration(seconds: 20),
}) async {
  final fin = DateTime.now().add(limite);
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> tocar(WidgetTester tester, String texto) async {
  final boton = find.text(texto);
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Future<void> escribir(WidgetTester tester, String campo, String valor) async {
  final finder = find.bySemanticsLabel(campo);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, valor);
  await tester.pumpAndSettle();
}

/// Entra a un campo y lo deja sin escribir nada.
Future<void> entrarYSalir(WidgetTester tester, String campo) async {
  final finder = find.bySemanticsLabel(campo);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

/// Abre la app desde el enlace del correo de recuperación, como lo haría Android.
Future<void> abrirEnlaceDeRecuperacion(
  WidgetTester tester,
  String codigo,
) async {
  await tester.binding.handlePushRoute('/recuperar?codigo=$codigo');
  await tester.pumpAndSettle();
}
