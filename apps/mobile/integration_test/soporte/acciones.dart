import 'package:clubnahuelmosse/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un valor que sólo usa este test: los escenarios afirman sobre datos propios.
String unico() => DateTime.now().microsecondsSinceEpoch.toString();

/// DNI de 8 dígitos derivado de [s], para que dos tests no choquen.
String dniDe(String s) =>
    (10000000 + int.parse(s.substring(s.length - 7))).toString();

/// Arranca la app real, contra la API y el emulador de Firebase de la corrida.
Future<void> abrirApp(WidgetTester tester) async {
  await app.main();
  await tester.pumpAndSettle();
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
