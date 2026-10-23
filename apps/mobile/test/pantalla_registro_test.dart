import 'dart:async';
import 'dart:io';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/comun/reglas_registro.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:clubnahuelmosse/usuarios/pantalla_registro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

void main() {
  Future<void> completar(WidgetTester tester) async {
    for (final (campo, valor) in [
      ('Nombre', 'Ana'),
      ('Apellido', 'Pérez'),
      ('DNI', '12345678'),
      ('Fecha de nacimiento', '14032000'),
      ('Correo electrónico', 'ana@correo.com'),
      ('Contraseña', 'ClubNahuel1'),
    ]) {
      await tester.enterText(find.bySemanticsLabel(campo), valor);
    }
    await tester.pump();
  }

  Future<void> tocar(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder, warnIfMissed: false);
  }

  bool botonHabilitado(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  testWidgets('reintentar después de un corte no manda pedidos en paralelo', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    var pedidos = 0;
    final segundo = Completer<http.Response>();
    final api = ClienteApi(
      'http://api.falsa',
      cliente: MockClient((_) {
        pedidos++;
        if (pedidos == 1) throw const SocketException('sin red');
        return segundo.future;
      }),
    );
    await montar(tester, PantallaRegistro(api: api), tema: temaOscuro);
    await completar(tester);

    await tocar(tester, find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('Error de conexión'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pump();
    await tester.pump();
    expect(pedidos, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tocar(
      tester,
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pump();
    expect(pedidos, 2);

    segundo.complete(
      http.Response('{"errores": {"dni": "El DNI tiene 7 u 8 numeros"}}', 422),
    );
    await tester.pumpAndSettle();
    expect(find.text('El DNI tiene 7 u 8 numeros'), findsOneWidget);
    expect(pedidos, 2);
    semantica.dispose();
  });

  testWidgets('el aviso de usuario repetido se va al corregir el correo', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(
      tester,
      PantallaRegistro(
        api: apiFalsa(
          codigo: 409,
          cuerpo:
              '{"mensaje": "El usuario ya está registrado. Modificá el correo o el DNI.",'
              ' "campos": ["correo"],'
              ' "errores": {"correo": "Este correo ya está registrado"}}',
        ),
      ),
      tema: temaOscuro,
    );
    await completar(tester);
    await tocar(tester, find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('Este correo ya está registrado'), findsOneWidget);
    expect(
      find.text('El usuario ya está registrado. Modificá el correo o el DNI.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.bySemanticsLabel('Correo electrónico'),
      'otra@correo.com',
    );
    await tester.pump();
    expect(find.text('Este correo ya está registrado'), findsNothing);
    expect(
      find.text('El usuario ya está registrado. Modificá el correo o el DNI.'),
      findsNothing,
    );
    expect(botonHabilitado(tester), isTrue);
    semantica.dispose();
  });

  testWidgets('una respuesta inesperada muestra el error del servidor', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(
      tester,
      PantallaRegistro(api: apiFalsa(codigo: 404, cuerpo: '<html>no</html>')),
      tema: temaOscuro,
    );
    await completar(tester);
    await tocar(tester, find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    expect(find.text('Error del servidor'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('un dato inválido escrito se marca al salir del campo', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, PantallaRegistro(api: apiFalsa()), tema: temaOscuro);

    await tester.enterText(find.bySemanticsLabel('Correo electrónico'), 'ana');
    await tester.tap(find.bySemanticsLabel('Nombre'));
    await tester.pumpAndSettle();

    expect(find.text(validarCorreo('ana')!), findsOneWidget);
    semantica.dispose();
  });
}
