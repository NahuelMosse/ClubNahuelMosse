import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'admin/pantalla_panel_admin.dart';
import 'api/cliente_api.dart';
import 'inicio/pantalla_inicio.dart';
import 'sesion/pantalla_inicio_sesion.dart';
import 'sesion/pantalla_recuperar_contrasena.dart';
import 'sesion/sesion.dart';
import 'tema/tema.dart';
import 'usuarios/pantalla_registro.dart';
import 'usuarios/pantalla_registro_exitoso.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.api,
    required this.sesion,
    this.inicio = '/',
  });

  final ClienteApi api;
  final Sesion sesion;

  /// Dónde arranca la app: el login, o el inicio de quien ya tenía la sesión abierta.
  final String inicio;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _rutas = GoRouter(
    initialLocation: widget.inicio,
    redirect: (context, estado) {
      // Sin sesión, las pantallas de adentro vuelven al login.
      final adentro =
          estado.matchedLocation == '/inicio' ||
          estado.matchedLocation == '/admin';
      return adentro && widget.sesion.perfil == null ? '/' : null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => PantallaInicioSesion(sesion: widget.sesion),
        routes: [
          GoRoute(
            path: 'registro',
            builder: (context, _) => PantallaRegistro(api: widget.api),
          ),
          GoRoute(
            path: 'registro/exitoso',
            builder: (context, _) => const PantallaRegistroExitoso(),
          ),
          GoRoute(
            path: 'recuperar-contrasena',
            builder: (context, _) => const PantallaRecuperarContrasena(),
          ),
        ],
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, _) =>
            PantallaInicio(nombre: widget.sesion.perfil?.nombre ?? ''),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) => const PantallaPanelAdmin(),
      ),
    ],
  );

  @override
  void dispose() {
    widget.api.cerrar();
    _rutas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ClubNahuelMosse',
      debugShowCheckedModeBanner: false,
      theme: temaClaro,
      darkTheme: temaOscuro,
      themeMode: ThemeMode.dark,
      routerConfig: _rutas,
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
