import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'admin/pantalla_alta_espacio.dart';
import 'admin/pantalla_editar_espacio.dart';
import 'admin/pantalla_formulario_sede.dart';
import 'admin/pantalla_espacio_creado.dart';
import 'admin/pantalla_espacios_admin.dart';
import 'admin/pantalla_panel_admin.dart';
import 'admin/pantalla_sede_creada.dart';
import 'admin/pantalla_sedes_admin.dart';
import 'espacios/espacio.dart';
import 'espacios/espacios.dart';
import 'sedes/sede.dart';
import 'sedes/sedes.dart';
import 'comun/apariencia.dart';
import 'api/cliente_api.dart';
import 'inicio/pantalla_inicio.dart';
import 'notificaciones/centro.dart';
import 'notificaciones/notificacion.dart';
import 'notificaciones/sistema.dart';
import 'notificaciones/panel_avisos.dart';
import 'notificaciones/pantalla_notificaciones.dart';
import 'reservas/pantalla_mis_reservas.dart';
import 'reservas/pantalla_reserva_confirmada.dart';
import 'reservas/reserva_pendiente.dart';
import 'reservas/reservas.dart';
import 'sesion/pantalla_inicio_sesion.dart';
import 'sesion/pantalla_nueva_contrasena.dart';
import 'sesion/pantalla_recuperar_contrasena.dart';
import 'sesion/recuperacion.dart';
import 'reservas/eleccion.dart';
import 'reservas/horarios.dart';
import 'reservas/pantalla_buscar_cancha.dart';
import 'reservas/pantalla_confirmar_cambio.dart';
import 'reservas/pantalla_confirmar_reserva.dart';
import 'reservas/pantalla_horarios.dart';
import 'sedes/pantalla_sede.dart';
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
    this.centro,
    this.inicio = '/',
  });

  final ClienteApi api;
  final Sesion sesion;
  final Apariencia apariencia;

  /// Las notificaciones de la app. Sin él no hay campana, ni panel, ni centro que consultar.
  final CentroDeNotificaciones? centro;

  /// Dónde arranca la app: el login, o el inicio de quien ya tenía la sesión abierta.
  final String inicio;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  /// Las secciones de adentro del usuario, con todo lo que cuelga de cada una; las del
  /// panel son las de `/admin`.
  static const _rolDe = {
    '/inicio': Rol.usuario,
    '/perfil': Rol.usuario,
    '/sedes': Rol.usuario,
    '/reservas': Rol.usuario,
    '/reservar': Rol.usuario,
    '/notificaciones': Rol.usuario,
  };

  late final _recuperacion = Recuperacion(widget.api);
  late final _sedes = Sedes(api: widget.api, sesion: widget.sesion);
  late final _espacios = Espacios(api: widget.api, sesion: widget.sesion);
  late final _horarios = Horarios(api: widget.api, sesion: widget.sesion);
  late final _reservas = Reservas(api: widget.api, sesion: widget.sesion);
  final _pendiente = ReservaPendiente();
  StreamSubscription<AvisoTocado>? _alTocarUnAviso;

  /// Mis reservas, con la reserva del aviso a la vista si el aviso trae una.
  /// El navegador de la app, para abrir el panel de avisos desde arriba del `Navigator`.
  final _navegador = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final centro = widget.centro;
    if (centro == null) return;
    centro.ubicacion = () =>
        _rutas.routerDelegate.currentConfiguration.uri.path;
    // Un aviso de la bandeja del sistema abre la app en la reserva que avisa.
    _alTocarUnAviso = centro.alTocarDesdeElSistema.listen(
      (aviso) => _rutas.go(rutaDelAviso(aviso.tipo, aviso.reservaId)),
    );
    unawaited(
      centro.abiertaPor().then((aviso) {
        if (aviso != null) {
          _rutas.go(rutaDelAviso(aviso.tipo, aviso.reservaId));
        }
      }),
    );
  }

  /// `AAAA-MM-DD` de un enlace como día del club; `null` si no viene o no es una fecha.
  static DateTime? _dia(String? iso) => switch (DateTime.tryParse(iso ?? '')) {
    final d? => DateTime.utc(d.year, d.month, d.day),
    null => null,
  };

  late final GoRouter _rutas = GoRouter(
    navigatorKey: _navegador,
    initialLocation: widget.inicio,
    // Al iniciar o cerrar la sesión, las rutas se vuelven a evaluar.
    refreshListenable: widget.sesion,
    redirect: (context, estado) {
      final ruta = estado.matchedLocation;
      // Todo lo que cuelga de /admin es del administrador: una ruta nueva del panel no
      // queda abierta por olvidarse de anotarla.
      final rol = ruta == '/admin' || ruta.startsWith('/admin/')
          ? Rol.admin
          : _rolDe.entries
                .where((e) => ruta == e.key || ruta.startsWith('${e.key}/'))
                .firstOrNull
                ?.value;
      final perfil = widget.sesion.perfil;
      if (rol == null) return null;
      if (perfil == null) return '/';
      return perfil.rol == rol ? null : perfil.inicio;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) =>
            PantallaInicioSesion(sesion: widget.sesion, pendiente: _pendiente),
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
        builder: (context, _) =>
            PantallaInicio(sesion: widget.sesion, centro: widget.centro),
        routes: [
          GoRoute(
            path: 'buscar',
            builder: (context, _) => PantallaBuscarCancha(
              sedes: _sedes,
              espacios: _espacios,
              horarios: _horarios,
              sesion: widget.sesion,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/notificaciones',
        builder: (context, _) => switch (widget.centro) {
          final CentroDeNotificaciones centro => PantallaNotificaciones(
            centro: centro,
            sesion: widget.sesion,
            alAbrir: (context, n) =>
                context.go(rutaDelAviso(n.tipo, n.reservaId)),
          ),
          null => const SizedBox.shrink(),
        },
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
      GoRoute(
        path: '/sedes',
        builder: (context, _) => PantallaSedes(
          sedes: _sedes,
          espacios: _espacios,
          sesion: widget.sesion,
        ),
        routes: [
          GoRoute(
            path: ':sede',
            builder: (context, estado) => PantallaSede(
              key: ValueKey(estado.pathParameters['sede']),
              sedeId: int.tryParse(estado.pathParameters['sede'] ?? '') ?? 0,
              sedes: _sedes,
              espacios: _espacios,
              sesion: widget.sesion,
            ),
            routes: [
              GoRoute(
                path: 'canchas/:cancha',
                builder: (context, estado) => PantallaHorarios(
                  key: ValueKey(estado.pathParameters['cancha']),
                  sedeId:
                      int.tryParse(estado.pathParameters['sede'] ?? '') ?? 0,
                  espacioId:
                      int.tryParse(estado.pathParameters['cancha'] ?? '') ?? 0,
                  sedes: _sedes,
                  espacios: _espacios,
                  horarios: _horarios,
                  sesion: widget.sesion,
                  fecha: _dia(estado.uri.queryParameters['fecha']),
                  horas: int.tryParse(
                    estado.uri.queryParameters['horas'] ?? '',
                  ),
                  inicio: estado.uri.queryParameters['inicio'],
                ),
                routes: [
                  GoRoute(
                    path: 'reservar',
                    redirect: (context, estado) => estado.extra is Eleccion
                        ? null
                        : '/sedes/${estado.pathParameters['sede']}'
                              '/canchas/${estado.pathParameters['cancha']}',
                    builder: (context, estado) => switch (estado.extra) {
                      final Eleccion eleccion => PantallaConfirmarReserva(
                        eleccion: eleccion,
                        reservas: _reservas,
                        pendiente: _pendiente,
                        sesion: widget.sesion,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/reservas',
        builder: (context, estado) => PantallaMisReservas(
          reservas: _reservas,
          espacios: _espacios,
          sesion: widget.sesion,
          reservaId: int.tryParse(estado.uri.queryParameters['reserva'] ?? ''),
          enHistorial: estado.uri.queryParameters['historial'] == '1',
        ),
        routes: [
          GoRoute(
            path: ':reserva/modificar',
            // La confirmación está anidada acá y trae su propio extra.
            redirect: (context, estado) => switch (estado.extra) {
              Reserva() || (Reserva(), Eleccion()) => null,
              _ => '/reservas',
            },
            builder: (context, estado) => switch (estado.extra) {
              final Reserva reserva => PantallaHorarios(
                sedeId: reserva.sedeId,
                espacioId: reserva.espacioId,
                sedes: _sedes,
                espacios: _espacios,
                horarios: _horarios,
                sesion: widget.sesion,
                modificando: reserva,
              ),
              _ => const SizedBox.shrink(),
            },
            routes: [
              GoRoute(
                path: 'confirmar',
                redirect: (context, estado) =>
                    estado.extra is (Reserva, Eleccion) ? null : '/reservas',
                builder: (context, estado) => switch (estado.extra) {
                  (final Reserva reserva, final Eleccion eleccion) =>
                    PantallaConfirmarCambio(
                      reserva: reserva,
                      eleccion: eleccion,
                      reservas: _reservas,
                      sesion: widget.sesion,
                    ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
          GoRoute(
            path: 'confirmada',
            redirect: (context, estado) =>
                estado.extra is Reserva ? null : '/reservas',
            builder: (context, estado) => switch (estado.extra) {
              final Reserva reserva => PantallaReservaConfirmada(
                reserva: reserva,
              ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      // La reserva que quedó pendiente cuando venció la sesión, al volver a entrar.
      GoRoute(
        path: '/reservar',
        redirect: (context, estado) =>
            estado.extra is Eleccion ? null : '/inicio',
        builder: (context, estado) => switch (estado.extra) {
          final Eleccion eleccion => PantallaConfirmarReserva(
            eleccion: eleccion,
            reservas: _reservas,
            pendiente: _pendiente,
            sesion: widget.sesion,
          ),
          _ => const SizedBox.shrink(),
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, _) => PantallaPanelAdmin(sesion: widget.sesion),
      ),
      GoRoute(
        path: '/admin/sedes',
        builder: (context, _) =>
            PantallaSedesAdmin(sedes: _sedes, sesion: widget.sesion),
        routes: [
          GoRoute(
            path: 'nueva',
            builder: (context, _) =>
                PantallaFormularioSede(sedes: _sedes, sesion: widget.sesion),
          ),
          GoRoute(
            path: ':sede/editar',
            // Sin la sede que se tocó en el listado (un enlace, la app reabierta), vuelve al
            // listado.
            redirect: (context, estado) =>
                estado.extra is Sede ? null : '/admin/sedes',
            builder: (context, estado) => switch (estado.extra) {
              final Sede sede => PantallaFormularioSede(
                sedes: _sedes,
                sesion: widget.sesion,
                editando: sede,
              ),
              _ => const SizedBox.shrink(),
            },
          ),
          GoRoute(
            path: 'creada',
            // Sin la sede recién guardada (un enlace, la app reabierta) no hay éxito que
            // mostrar: va al listado, donde está.
            redirect: (context, estado) =>
                estado.extra is Sede ? null : '/admin/sedes',
            builder: (context, estado) => switch (estado.extra) {
              final Sede sede => PantallaSedeCreada(sede: sede),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/espacios',
        builder: (context, _) =>
            PantallaEspaciosAdmin(espacios: _espacios, sesion: widget.sesion),
        routes: [
          GoRoute(
            path: ':espacio/editar',
            // Sin el espacio que se tocó en el listado (un enlace, la app reabierta), vuelve
            // al listado.
            redirect: (context, estado) =>
                estado.extra is Espacio ? null : '/admin/espacios',
            builder: (context, estado) => switch (estado.extra) {
              final Espacio espacio => PantallaEditarEspacio(
                espacio: espacio,
                espacios: _espacios,
                sesion: widget.sesion,
              ),
              _ => const SizedBox.shrink(),
            },
          ),
          GoRoute(
            path: 'nuevo',
            builder: (context, _) => PantallaAltaEspacio(
              espacios: _espacios,
              sedes: _sedes,
              sesion: widget.sesion,
            ),
          ),
          GoRoute(
            path: 'creado',
            // Sin el espacio recién guardado no hay éxito que mostrar: va al listado.
            redirect: (context, estado) =>
                estado.extra is Espacio ? null : '/admin/espacios',
            builder: (context, estado) => switch (estado.extra) {
              final Espacio espacio => PantallaEspacioCreado(espacio: espacio),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    unawaited(_alTocarUnAviso?.cancel());
    widget.centro?.dispose();
    widget.api.cerrar();
    _sedes.dispose();
    _espacios.dispose();
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
        builder: (context, hijo) => Stack(
          children: [
            hijo ?? const SizedBox.shrink(),
            if (widget.centro case final centro?)
              PanelDeAvisos(
                centro: centro,
                navegador: _navegador,
                alAbrir: (n) {
                  centro.marcarLeida(n);
                  _rutas.go(rutaDelAviso(n.tipo, n.reservaId));
                },
              ),
          ],
        ),
        locale: const Locale('es', 'AR'),
        supportedLocales: const [Locale('es', 'AR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    );
  }
}
