import 'dart:async';

import 'package:clubnahuelmosse/api/api_client.dart';
import 'package:clubnahuelmosse/app.dart';
import 'package:clubnahuelmosse/common/appearance.dart';
import 'package:clubnahuelmosse/common/error_dialog.dart';
import 'package:clubnahuelmosse/features/session/domain/profile.dart';
import 'package:clubnahuelmosse/features/session/presentation/access_denied_screen.dart';
import 'package:clubnahuelmosse/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'soporte/admin.dart';
import 'soporte/montar.dart';

/// La API respondiendo siempre 403, como con un rol que ya no alcanza.
ApiClient _api403() => ApiClient(
  'http://api.falsa',
  cliente: MockClient((_) async => http.Response('{}', 403)),
);

/// Una sesión que abrió como administrador y, al volver a leer el perfil, ya es usuario.
class _SesionDegradada extends SesionFalsa {
  _SesionDegradada() : super(perfilAdmin);

  int lecturas = 0;
  Profile? _rebajado;

  @override
  Profile? get profile => _rebajado ?? super.profile;

  @override
  Future<Profile> refresh() async {
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
      (c) => showNetworkError(c, const SinConexion()),
    ),
    'error del servidor': (
      'ACEPTAR',
      (c) => showNetworkError(c, const ErrorDelServidor(500)),
    ),
    'sesión expirada': ('IR AL INICIO DE SESIÓN', showSessionExpired),
    'esto cambió mientras tanto': ('VER LO ACTUALIZADO', showChangedMeanwhile),
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
        tema: darkTheme,
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
      AccessDeniedScreen(session: SesionFalsa(perfilUsuario)),
      tema: darkTheme,
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
                    showNetworkError(context, const ErrorDelServidor(403)),
                child: const Text('ABRIR'),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/acceso-denegado',
            builder: (context, _) =>
                AccessDeniedScreen(session: SesionFalsa(perfilUsuario)),
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, _) => const Scaffold(body: Text('Mis reservas')),
          ),
        ],
      );
      addTearDown(rutas.dispose);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: rutas, theme: darkTheme),
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
          api: apiRutas({'GET /bookings': (200, '{"bookings": []}')}),
          session: SesionFalsa(perfilUsuario),
          appearance: Appearance.inMemory(),
          initialLocation: '/admin',
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
          api: ApiClient(
            'http://api.falsa',
            cliente: MockClient(
              (pedido) async => switch (pedido.url.path) {
                '/bookings' => http.Response('{"bookings": []}', 200),
                '/spaces/catalog' => http.Response(catalogoJson, 200),
                _ => http.Response('{}', 403),
              },
            ),
          ),
          session: sesion,
          appearance: Appearance.inMemory(),
          initialLocation: '/admin/sedes',
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
        session: sesion,
        appearance: Appearance.inMemory(),
        initialLocation: '/admin',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(sesion.cierres, 1);
    expect(find.text('Acceso denegado'), findsNothing);
  });

  testWidgets('un 403 devuelve su propio resultado', (tester) async {
    ErrorOutcome? resultado;
    final rutas = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => resultado = await handleNetworkError(
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
              AccessDeniedScreen(session: SesionFalsa(perfilUsuario)),
        ),
      ],
    );
    addTearDown(rutas.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: rutas, theme: darkTheme),
    );
    await tester.tap(find.text('ABRIR'));
    await tester.pumpAndSettle();

    expect(resultado, ErrorOutcome.accessDenied);
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
        session: SesionFalsa(perfilUsuario),
        appearance: Appearance.inMemory(),
        initialLocation: '/sedes/00000000-0000-7000-8000-000000000001',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Acceso denegado'), findsOneWidget);
  });

  test(
    'una API que no responde en el límite se trata como sin respuesta del servidor',
    () async {
      final api = ApiClient(
        'http://api.falsa',
        limite: const Duration(milliseconds: 50),
        cliente: MockClient((_) => Completer<http.Response>().future),
      );

      await expectLater(
        api.get('/venues'),
        throwsA(isA<ServidorSinRespuesta>()),
      );
    },
  );
}
