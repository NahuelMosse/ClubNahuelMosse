import 'dart:async';

import 'package:clubnahuelmosse/api/cliente_api.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/comun/apariencia.dart';
import 'package:clubnahuelmosse/comun/dialogo_error.dart';
import 'package:clubnahuelmosse/comun/pantalla_acceso_denegado.dart';
import 'package:clubnahuelmosse/sesion/sesion.dart';
import 'package:clubnahuelmosse/tema/tema.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

/// La API respondiendo siempre 403, como con un rol que ya no alcanza.
ClienteApi _api403() => ClienteApi(
  'http://api.falsa',
  cliente: MockClient((_) async => http.Response('{}', 403)),
);

/// Una sesión que abrió como administrador y, al volver a leer el perfil, ya es usuario.
class _SesionDegradada extends SesionFalsa {
  _SesionDegradada() : super(perfilAdmin);

  int lecturas = 0;
  Perfil? _rebajado;

  @override
  Perfil? get perfil => _rebajado ?? super.perfil;

  @override
  Future<Perfil> refrescar() async {
    lecturas++;
    _rebajado = perfilUsuario;
    notifyListeners();
    return perfilUsuario;
  }
}

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

  testWidgets('«Acceso denegado» entra en 360 con el texto al 200 %', (
    tester,
  ) async {
    await montar(
      tester,
      PantallaAccesoDenegado(sesion: SesionFalsa(perfilUsuario)),
      tema: temaOscuro,
      tamano: const Size(360, 800),
      escalaTexto: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('IR A MIS RESERVAS'), findsOneWidget);
  });

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
            path: '/admin/acceso-denegado',
            builder: (context, _) =>
                PantallaAccesoDenegado(sesion: SesionFalsa(perfilUsuario)),
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

  testWidgets(
    'un administrador degradado sale de «Acceso denegado» a Mis reservas sin volver al panel',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final sesion = _SesionDegradada();
      await tester.pumpWidget(
        App(
          api: ClienteApi(
            'http://api.falsa',
            cliente: MockClient(
              (pedido) async => switch (pedido.url.path) {
                '/reservas' => http.Response('{"reservas": []}', 200),
                '/espacios/catalogo' => http.Response(catalogoJson, 200),
                _ => http.Response('{}', 403),
              },
            ),
          ),
          sesion: sesion,
          apariencia: Apariencia.enMemoria(),
          inicio: '/admin/sedes',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Acceso denegado'), findsOneWidget);

      await tester.tap(find.text('IR A MIS RESERVAS'));
      await tester.pumpAndSettle();

      expect(sesion.lecturas, greaterThan(0));
      expect(find.text('Acceso denegado'), findsNothing);
      expect(find.text('PANEL ADMIN'), findsNothing);
      expect(find.text('Mis reservas'), findsWidgets);
    },
  );

  testWidgets('«Acceso denegado» ofrece cerrar la sesión', (tester) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final sesion = SesionFalsa(perfilUsuario);
    await tester.pumpWidget(
      App(
        api: apiRutas({}),
        sesion: sesion,
        apariencia: Apariencia.enMemoria(),
        inicio: '/admin',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(sesion.cierres, 1);
    expect(find.text('Acceso denegado'), findsNothing);
  });

  testWidgets('un 403 devuelve su propio resultado', (tester) async {
    ResultadoDeError? resultado;
    final rutas = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => resultado = await atenderErrorDeRed(
                context,
                const ErrorDelServidor(403),
              ),
              child: const Text('ABRIR'),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/acceso-denegado',
          builder: (context, _) =>
              PantallaAccesoDenegado(sesion: SesionFalsa(perfilUsuario)),
        ),
      ],
    );
    addTearDown(rutas.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: rutas, theme: temaOscuro),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();

    expect(resultado, ResultadoDeError.accesoDenegado);
  });

  testWidgets(
    'un 403 al cargar el alta de espacio no navega sobre «Acceso denegado»',
    (tester) async {
      await montarAdmin(
        tester,
        api: _api403(),
        inicio: '/admin/espacios/nuevo',
      );
      await tester.pumpAndSettle();

      expect(find.text('Acceso denegado'), findsOneWidget);
      expect(find.text('Error del servidor'), findsNothing);
    },
  );

  testWidgets('un 403 al cargar una sede no navega sobre «Acceso denegado»', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      App(
        api: _api403(),
        sesion: SesionFalsa(perfilUsuario),
        apariencia: Apariencia.enMemoria(),
        inicio: '/sedes/1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acceso denegado'), findsOneWidget);
  });

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
