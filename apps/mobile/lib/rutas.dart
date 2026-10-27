import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'admin/historial_reservas.dart';
import 'admin/pantalla_alta_espacio.dart';
import 'admin/pantalla_detalle_reserva.dart';
import 'admin/pantalla_editar_espacio.dart';
import 'admin/pantalla_espacio_creado.dart';
import 'admin/pantalla_espacios_admin.dart';
import 'admin/pantalla_formulario_sede.dart';
import 'admin/pantalla_panel_admin.dart';
import 'admin/pantalla_sede_creada.dart';
import 'admin/pantalla_sedes_admin.dart';
import 'api/cliente_api.dart';
import 'comun/apariencia.dart';
import 'comun/reserva_pendiente.dart';
import 'comun/transiciones.dart';
import 'espacios/espacio.dart';
import 'espacios/espacios.dart';
import 'inicio/pantalla_inicio.dart';
import 'notificaciones/centro.dart';
import 'notificaciones/notificacion.dart';
import 'notificaciones/pantalla_notificaciones.dart';
import 'redireccion.dart';
import 'reservas/eleccion.dart';
import 'reservas/horarios.dart';
import 'reservas/pantalla_buscar_cancha.dart';
import 'reservas/pantalla_confirmar_cambio.dart';
import 'reservas/pantalla_confirmar_reserva.dart';
import 'reservas/pantalla_horarios.dart';
import 'reservas/pantalla_mis_reservas.dart';
import 'reservas/pantalla_reserva_confirmada.dart';
import 'reservas/reservas.dart';
import 'sedes/pantalla_sede.dart';
import 'sedes/pantalla_sedes.dart';
import 'sedes/sede.dart';
import 'sedes/sedes.dart';
import 'sesion/pantalla_acceso_denegado.dart';
import 'sesion/pantalla_inicio_sesion.dart';
import 'sesion/pantalla_nueva_contrasena.dart';
import 'sesion/pantalla_recuperar_contrasena.dart';
import 'sesion/recuperacion.dart';
import 'sesion/sesion.dart';
import 'usuarios/pantalla_cambiar_contrasena.dart';
import 'usuarios/pantalla_mi_perfil.dart';
import 'usuarios/pantalla_registro.dart';
import 'usuarios/pantalla_registro_exitoso.dart';

/// Las rutas de la app, con lo que cada pantalla recibe.
class Rutas {
  const Rutas({
    required ValueGetter<ClienteApi> api,
    required ValueGetter<Sesion> sesion,
    required ValueGetter<Apariencia> apariencia,
    required ValueGetter<CentroDeNotificaciones?> centro,
    required this.recuperacion,
    required this.sedes,
    required this.espacios,
    required this.horarios,
    required this.reservas,
    required this.historialAdmin,
    required this.pendiente,
    required this.filtrosPendientes,
  }) : _api = api,
       _sesion = sesion,
       _apariencia = apariencia,
       _centro = centro;

  // Se leen de la app en cada uso: si el widget se reemplaza con la misma `State`,
  // las rutas siguen con lo que trae el widget nuevo.
  final ValueGetter<ClienteApi> _api;
  final ValueGetter<Sesion> _sesion;
  final ValueGetter<Apariencia> _apariencia;
  final ValueGetter<CentroDeNotificaciones?> _centro;
  final Recuperacion recuperacion;
  final Sedes sedes;
  final Espacios espacios;
  final Horarios horarios;
  final Reservas reservas;
  final HistorialDeReservas historialAdmin;
  final ReservaPendiente<Eleccion> pendiente;
  final FiltrosDePanelPendientes filtrosPendientes;

  ClienteApi get api => _api();
  Sesion get sesion => _sesion();
  Apariencia get apariencia => _apariencia();
  CentroDeNotificaciones? get centro => _centro();

  /// El router de la app: arranca en [inicio] y, al iniciar o cerrar la sesión, vuelve a
  /// evaluar a quién deja pasar adónde.
  GoRouter router({
    required GlobalKey<NavigatorState> navegador,
    required String inicio,
  }) => GoRouter(
    navigatorKey: navegador,
    initialLocation: inicio,
    refreshListenable: sesion,
    redirect: (context, estado) =>
        redirigirSegunRol(estado.matchedLocation, sesion.perfil),
    routes: [
      ..._deSesion(),
      ..._deInicio(),
      ..._deSedes(),
      ..._deReservas(),
      ..._deAdmin(),
    ],
  );

  /// `AAAA-MM-DD` de un enlace como día del club; `null` si no viene o no es una fecha.
  static DateTime? _dia(String? iso) => switch (DateTime.tryParse(iso ?? '')) {
    final d? => DateTime.utc(d.year, d.month, d.day),
    null => null,
  };

  List<RouteBase> _deSesion() => [
    GoRoute(
      path: '/',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaInicioSesion(sesion: sesion, pendiente: pendiente),
      ),
      routes: [
        GoRoute(
          path: 'registro',
          pageBuilder: (context, estado) =>
              paginaQueAvanza(context, estado, PantallaRegistro(api: api)),
        ),
        GoRoute(
          path: 'registro/exitoso',
          pageBuilder: (context, estado) => paginaDeResultado(
            context,
            estado,
            const PantallaRegistroExitoso(),
          ),
        ),
        GoRoute(
          path: 'recuperar-contrasena',
          pageBuilder: (context, estado) => paginaQueAvanza(
            context,
            estado,
            PantallaRecuperarContrasena(recuperacion: recuperacion),
          ),
        ),
      ],
    ),
    // Adonde abre el enlace del correo: clubnahuelmosse://app/recuperar?codigo=…
    GoRoute(
      path: '/recuperar',
      pageBuilder: (context, estado) {
        final codigo = estado.uri.queryParameters['codigo'] ?? '';
        // Un enlace nuevo con la pantalla ya abierta es otra pantalla, no la misma.
        return paginaQueAvanza(
          context,
          estado,
          PantallaNuevaContrasena(
            key: ValueKey(codigo),
            recuperacion: recuperacion,
            sesion: sesion,
            codigo: codigo,
          ),
        );
      },
    ),
  ];

  List<RouteBase> _deInicio() => [
    GoRoute(
      path: '/inicio',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaInicio(
          sesion: sesion,
          reservas: reservas,
          espacios: espacios,
          sedes: sedes,
          centro: centro,
        ),
      ),
      routes: [
        GoRoute(
          path: 'buscar',
          pageBuilder: (context, estado) => paginaQueAvanza(
            context,
            estado,
            PantallaBuscarCancha(
              sedes: sedes,
              espacios: espacios,
              horarios: horarios,
              sesion: sesion,
              deporte: estado.uri.queryParameters['deporte'],
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/notificaciones',
      pageBuilder: (context, estado) =>
          paginaQueAvanza(context, estado, switch (centro) {
            final CentroDeNotificaciones centro => PantallaNotificaciones(
              centro: centro,
              sesion: sesion,
              alAbrir: (context, n) =>
                  context.go(rutaDelAviso(n.tipo, n.reservaId)),
            ),
            null => const SizedBox.shrink(),
          }),
    ),
    GoRoute(
      path: '/perfil',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaMiPerfil(sesion: sesion, apariencia: apariencia),
      ),
      routes: [
        GoRoute(
          path: 'contrasena',
          pageBuilder: (context, estado) => paginaQueAvanza(
            context,
            estado,
            PantallaCambiarContrasena(sesion: sesion),
          ),
        ),
      ],
    ),
  ];

  List<RouteBase> _deSedes() => [
    GoRoute(
      path: '/sedes',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaSedes(sedes: sedes, espacios: espacios, sesion: sesion),
      ),
      routes: [
        GoRoute(
          path: ':sede',
          pageBuilder: (context, estado) => paginaQueAvanza(
            context,
            estado,
            PantallaSede(
              key: ValueKey(estado.pathParameters['sede']),
              sedeId: estado.pathParameters['sede'] ?? '',
              sedes: sedes,
              espacios: espacios,
              sesion: sesion,
            ),
          ),
          routes: [
            GoRoute(
              path: 'canchas/:cancha',
              pageBuilder: (context, estado) => paginaQueAvanza(
                context,
                estado,
                PantallaHorarios(
                  key: ValueKey(estado.pathParameters['cancha']),
                  sedeId: estado.pathParameters['sede'] ?? '',
                  espacioId: estado.pathParameters['cancha'] ?? '',
                  sedes: sedes,
                  espacios: espacios,
                  horarios: horarios,
                  sesion: sesion,
                  fecha: _dia(estado.uri.queryParameters['fecha']),
                  horas: int.tryParse(
                    estado.uri.queryParameters['horas'] ?? '',
                  ),
                  inicio: estado.uri.queryParameters['inicio'],
                ),
              ),
              routes: [
                GoRoute(
                  path: 'reservar',
                  redirect: (context, estado) => estado.extra is Eleccion
                      ? null
                      : '/sedes/${estado.pathParameters['sede']}'
                            '/canchas/${estado.pathParameters['cancha']}',
                  pageBuilder: (context, estado) => paginaQueAvanza(
                    context,
                    estado,
                    _confirmarReserva(estado),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];

  /// La confirmación de una reserva nueva; sin la elección, nada que mostrar.
  Widget _confirmarReserva(GoRouterState estado) => switch (estado.extra) {
    final Eleccion eleccion => PantallaConfirmarReserva(
      eleccion: eleccion,
      reservas: reservas,
      pendiente: pendiente,
      sesion: sesion,
    ),
    _ => const SizedBox.shrink(),
  };

  List<RouteBase> _deReservas() => [
    GoRoute(
      path: '/reservas',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaMisReservas(
          reservas: reservas,
          espacios: espacios,
          sesion: sesion,
          reservaId: estado.uri.queryParameters['reserva'],
          enHistorial: estado.uri.queryParameters['historial'] == '1',
        ),
      ),
      routes: [
        GoRoute(
          path: ':reserva/modificar',
          // La confirmación está anidada acá y trae su propio extra.
          redirect: (context, estado) => switch (estado.extra) {
            Reserva() || (Reserva(), Eleccion()) => null,
            _ => '/reservas',
          },
          pageBuilder: (context, estado) =>
              paginaQueAvanza(context, estado, switch (estado.extra) {
                final Reserva reserva => PantallaHorarios(
                  sedeId: reserva.sedeId,
                  espacioId: reserva.espacioId,
                  sedes: sedes,
                  espacios: espacios,
                  horarios: horarios,
                  sesion: sesion,
                  modificando: reserva,
                  volverA: estado.uri.queryParameters['desde'] == 'inicio'
                      ? 'Inicio'
                      : 'Mis reservas',
                ),
                _ => const SizedBox.shrink(),
              }),
          routes: [
            GoRoute(
              path: 'confirmar',
              redirect: (context, estado) =>
                  estado.extra is (Reserva, Eleccion) ? null : '/reservas',
              pageBuilder: (context, estado) =>
                  paginaQueAvanza(context, estado, switch (estado.extra) {
                    (final Reserva reserva, final Eleccion eleccion) =>
                      PantallaConfirmarCambio(
                        reserva: reserva,
                        eleccion: eleccion,
                        reservas: reservas,
                        sesion: sesion,
                      ),
                    _ => const SizedBox.shrink(),
                  }),
            ),
          ],
        ),
        GoRoute(
          path: 'confirmada',
          redirect: (context, estado) =>
              estado.extra is Reserva ? null : '/reservas',
          pageBuilder: (context, estado) =>
              paginaDeResultado(context, estado, switch (estado.extra) {
                final Reserva reserva => PantallaReservaConfirmada(
                  reserva: reserva,
                ),
                _ => const SizedBox.shrink(),
              }),
        ),
      ],
    ),
    // La reserva que quedó pendiente cuando venció la sesión, al volver a entrar.
    GoRoute(
      path: '/reservar',
      redirect: (context, estado) =>
          estado.extra is Eleccion ? null : '/inicio',
      pageBuilder: (context, estado) =>
          paginaQueAvanza(context, estado, _confirmarReserva(estado)),
    ),
  ];

  List<RouteBase> _deAdmin() => [
    ..._deReservasAdmin(),
    GoRoute(
      path: '/admin/acceso-denegado',
      pageBuilder: (context, estado) => paginaQueAvanza(
        context,
        estado,
        PantallaAccesoDenegado(sesion: sesion),
      ),
    ),
    ..._deSedesAdmin(),
    ..._deEspaciosAdmin(),
  ];

  List<RouteBase> _deReservasAdmin() => [
    GoRoute(
      path: '/admin',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaPanelAdmin(
          historial: historialAdmin,
          sedes: sedes,
          espacios: espacios,
          sesion: sesion,
          pendientes: filtrosPendientes,
        ),
      ),
      routes: [
        GoRoute(
          path: 'reserva/:id',
          // Sin la reserva y los filtros del listado de donde se vino (un enlace, la app
          // reabierta), vuelve al listado.
          redirect: (context, estado) =>
              estado.extra is (ReservaHistorial, FiltrosDeHistorial)
              ? null
              : '/admin',
          pageBuilder: (context, estado) =>
              paginaQueAvanza(context, estado, switch (estado.extra) {
                final (ReservaHistorial, FiltrosDeHistorial) e =>
                  PantallaDetalleReserva(
                    reserva: e.$1,
                    filtros: e.$2,
                    historial: historialAdmin,
                    sesion: sesion,
                    espacios: espacios,
                    pendientes: filtrosPendientes,
                  ),
                _ => const SizedBox.shrink(),
              }),
        ),
      ],
    ),
  ];

  List<RouteBase> _deSedesAdmin() => [
    GoRoute(
      path: '/admin/sedes',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaSedesAdmin(sedes: sedes, sesion: sesion),
      ),
      routes: [
        GoRoute(
          path: 'nueva',
          pageBuilder: (context, estado) => paginaQueAvanza(
            context,
            estado,
            PantallaFormularioSede(sedes: sedes, sesion: sesion),
          ),
        ),
        GoRoute(
          path: ':sede/editar',
          // Sin la sede que se tocó en el listado (un enlace, la app reabierta), vuelve al
          // listado.
          redirect: (context, estado) =>
              estado.extra is Sede ? null : '/admin/sedes',
          pageBuilder: (context, estado) =>
              paginaQueAvanza(context, estado, switch (estado.extra) {
                final Sede sede => PantallaFormularioSede(
                  sedes: sedes,
                  sesion: sesion,
                  editando: sede,
                ),
                _ => const SizedBox.shrink(),
              }),
        ),
        GoRoute(
          path: 'creada',
          // Sin la sede recién guardada (un enlace, la app reabierta) no hay éxito que
          // mostrar: va al listado, donde está.
          redirect: (context, estado) =>
              estado.extra is Sede ? null : '/admin/sedes',
          pageBuilder: (context, estado) =>
              paginaDeResultado(context, estado, switch (estado.extra) {
                final Sede sede => PantallaSedeCreada(sede: sede),
                _ => const SizedBox.shrink(),
              }),
        ),
      ],
    ),
  ];

  List<RouteBase> _deEspaciosAdmin() => [
    GoRoute(
      path: '/admin/espacios',
      pageBuilder: (context, estado) => paginaDeRaiz(
        context,
        estado,
        PantallaEspaciosAdmin(espacios: espacios, sesion: sesion),
      ),
      routes: [
        GoRoute(
          path: ':espacio/editar',
          // Sin el espacio que se tocó en el listado (un enlace, la app reabierta), vuelve
          // al listado.
          redirect: (context, estado) =>
              estado.extra is Espacio ? null : '/admin/espacios',
          pageBuilder: (context, estado) =>
              paginaQueAvanza(context, estado, switch (estado.extra) {
                final Espacio espacio => PantallaEditarEspacio(
                  espacio: espacio,
                  espacios: espacios,
                  sesion: sesion,
                ),
                _ => const SizedBox.shrink(),
              }),
        ),
        GoRoute(
          path: 'nuevo',
          pageBuilder: (context, estado) => paginaQueAvanza(
            context,
            estado,
            PantallaAltaEspacio(
              espacios: espacios,
              sedes: sedes,
              sesion: sesion,
            ),
          ),
        ),
        GoRoute(
          path: 'creado',
          // Sin el espacio recién guardado no hay éxito que mostrar: va al listado.
          redirect: (context, estado) =>
              estado.extra is Espacio ? null : '/admin/espacios',
          pageBuilder: (context, estado) => paginaDeResultado(
            context,
            estado,
            switch (estado.extra) {
              final Espacio espacio => PantallaEspacioCreado(espacio: espacio),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
      ],
    ),
  ];
}
