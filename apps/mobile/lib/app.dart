import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'admin/pantalla_panel_admin.dart';
import 'comun/apariencia.dart';
import 'api/cliente_api.dart';
import 'inicio/pantalla_inicio.dart';
import 'reservas/pantalla_mis_reservas.dart';
import 'sesion/pantalla_inicio_sesion.dart';
import 'sesion/pantalla_nueva_contrasena.dart';
import 'sesion/pantalla_recuperar_contrasena.dart';
import 'sesion/recuperacion.dart';
import 'sedes/pantalla_sedes.dart';
import 'sesion/sesion.dart';
import 'tema/tema.dart';
import 'usuarios/pantalla_cambiar_contrasena.dart';
import 'usuarios/pantalla_mi_perfil.dart';
import 'usuarios/pantalla_registro.dart';
import 'usuarios/pantalla_registro_exitoso.dart';

class App extends StatefulWidget {
  const App({
    super.key,
    required this.api,
    required this.sesion,
    required this.apariencia,
    this.inicio = '/',
  });

  final ClienteApi api;
  final Sesion sesion;
  final Apariencia apariencia;

  /// Dónde arranca la app: el login, o el inicio de quien ya tenía la sesión abierta.
  final String inicio;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  /// Las pantallas de adentro y el rol que las usa.
  static const _rolDe = {
    '/inicio': Rol.usuario,
    '/perfil': Rol.usuario,
    '/perfil/contrasena': Rol.usuario,
    '/sedes': Rol.usuario,
    '/reservas': Rol.usuario,
    '/admin': Rol.admin,
  };

  late final _recuperacion = Recuperacion(widget.api);

  late final GoRouter _rutas = GoRouter(
    initialLocation: widget.inicio,
    // Al iniciar o cerrar la sesión, las rutas se vuelven a evaluar.
    refreshListenable: widget.sesion,
    redirect: (context, estado) {
      final rol = _rolDe[estado.matchedLocation];
      final perfil = widget.sesion.perfil;
      if (rol == null) return null;
      if (perfil == null) return '/';
      return perfil.rol == rol ? null : perfil.inicio;
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
            builder: (context, _) =>
                PantallaRecuperarContrasena(recuperacion: _recuperacion),
          ),
        ],
      ),
      // Adonde abre el enlace del correo: clubnahuelmosse://app/recuperar?codigo=…
      GoRoute(
        path: '/recuperar',
        builder: (context, estado) {
          final codigo = estado.uri.queryParameters['codigo'] ?? '';
          // Un enlace nuevo con la pantalla ya abierta es otra pantalla, no la misma.
          return PantallaNuevaContrasena(
            key: ValueKey(codigo),
            recuperacion: _recuperacion,
            sesion: widget.sesion,
            codigo: codigo,
          );
        },
      ),
      GoRoute(
        path: '/inicio',
        builder: (context, _) => PantallaInicio(sesion: widget.sesion),
      ),
      GoRoute(
        path: '/perfil',
        builder: (context, _) => PantallaMiPerfil(
          sesion: widget.sesion,
          apariencia: widget.apariencia,
        ),
        routes: [
          GoRoute(
            path: 'contrasena',
            builder: (context, _) =>
                PantallaCambiarContrasena(sesion: widget.sesion),
          ),
        ],
      ),
      GoRoute(path: '/sedes', builder: (context, _) => const PantallaSedes()),
      GoRoute(
        path: '/reservas',
        builder: (context, _) => const PantallaMisReservas(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) => PantallaPanelAdmin(sesion: widget.sesion),
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
    return ListenableBuilder(
      listenable: widget.apariencia,
      builder: (context, _) => MaterialApp.router(
        title: 'ClubNahuelMosse',
        debugShowCheckedModeBanner: false,
        theme: temaClaro,
        darkTheme: temaOscuro,
        themeMode: widget.apariencia.modo,
        routerConfig: _rutas,
        locale: const Locale('es', 'AR'),
        supportedLocales: const [Locale('es', 'AR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
