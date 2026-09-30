import 'dart:async';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/comun/dialogo_error.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/montar.dart';

void main() {
  setUpAll(cargarFuentes);

  final avisos = <String, (String, Future<void> Function(BuildContext))>{
    'error de conexión': (
      'REINTENTAR',
      (c) => mostrarErrorDeRed(c, const SinConexion()),
    ),
    'error del servidor': (
      'ACEPTAR',
      (c) => mostrarErrorDeRed(c, const ErrorDelServidor(500)),
    ),
    'sesión expirada': ('IR AL INICIO DE SESIÓN', mostrarSesionVencida),
    'acceso denegado': ('IR A MIS RESERVAS', mostrarAccesoDenegado),
    'esto cambió mientras tanto': (
      'VER LO ACTUALIZADO',
      mostrarCambioMientrasTanto,
    ),
  };

  for (final MapEntry(key: nombre, value: (boton, abrir)) in avisos.entries) {
    testWidgets('el aviso de $nombre entra en 360 con el texto al 200 %', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => abrir(context),
                child: const Text('ABRIR'),
              ),
            ),
          ),
        ),
        tema: temaOscuro,
        tamano: const Size(360, 800),
        escalaTexto: 2,
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text(boton));
      await tester.pumpAndSettle();
      expect(find.text(boton), findsOneWidget);
      semantica.dispose();
    });
  }

  testWidgets(
    'un 403 de la API muestra «Acceso denegado» y lleva a Mis reservas',
    (tester) async {
      final rutas = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    mostrarErrorDeRed(context, const ErrorDelServidor(403)),
                child: const Text('ABRIR'),
              ),
            ),
          ),
          GoRoute(
            path: '/reservas',
            builder: (context, _) => const Scaffold(body: Text('Mis reservas')),
          ),
        ],
      );
      addTearDown(rutas.dispose);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: rutas, theme: temaOscuro),
      );
      await tester.tap(find.text('ABRIR'));
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
      expect(find.text('Error del servidor'), findsNothing);
      await tester.tap(find.text('IR A MIS RESERVAS'));
      await tester.pumpAndSettle();
      expect(find.text('Mis reservas'), findsOneWidget);
      expect(find.text('Acceso denegado'), findsNothing);
    },
  );

  testWidgets(
    'un usuario que entra al panel ve «Acceso denegado» y llega a Mis reservas',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        App(
          api: apiRutas({'GET /reservas': (200, '{"reservas": []}')}),
          sesion: SesionFalsa(perfilUsuario),
          apariencia: Apariencia.enMemoria(),
          inicio: '/admin',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
      expect(find.text('PANEL ADMIN'), findsNothing);
      await tester.tap(find.text('IR A MIS RESERVAS'));
      await tester.pumpAndSettle();
      expect(find.text('Acceso denegado'), findsNothing);
      expect(find.text('Mis reservas'), findsWidgets);
    },
  );

  test(
    'una API que no responde en el límite se trata como inalcanzable',
    () async {
      final api = ClienteApi(
        'http://api.falsa',
        limite: const Duration(milliseconds: 50),
        cliente: MockClient((_) => Completer<http.Response>().future),
      );

      await expectLater(api.get('/sedes'), throwsA(isA<SinConexion>()));
    },
  );
}
