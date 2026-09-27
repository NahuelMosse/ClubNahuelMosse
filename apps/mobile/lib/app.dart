import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'api/cliente_api.dart';
import 'configuracion.dart';
import 'sesion/pantalla_inicio_sesion.dart';
import 'tema/tema.dart';
import 'usuarios/pantalla_registro.dart';
import 'usuarios/pantalla_registro_exitoso.dart';

class App extends StatefulWidget {
  const App({super.key, required this.configuracion});

  final Configuracion configuracion;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final ClienteApi _api = ClienteApi(widget.configuracion.apiUrl);

  late final GoRouter _rutas = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => const PantallaInicioSesion(),
        routes: [
          GoRoute(
            path: 'registro',
            builder: (context, _) => PantallaRegistro(api: _api),
          ),
          GoRoute(
            path: 'registro/exitoso',
            builder: (context, _) => const PantallaRegistroExitoso(),
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    _api.cerrar();
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
