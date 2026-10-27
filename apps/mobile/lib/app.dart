import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'admin/historial_reservas.dart';
import 'api/cliente_api.dart';
import 'comun/apariencia.dart';
import 'comun/reserva_pendiente.dart';
import 'espacios/espacios.dart';
import 'notificaciones/centro.dart';
import 'notificaciones/notificacion.dart';
import 'notificaciones/panel_avisos.dart';
import 'notificaciones/sistema.dart';
import 'reservas/eleccion.dart';
import 'reservas/horarios.dart';
import 'reservas/reservas.dart';
import 'rutas.dart';
import 'sedes/sedes.dart';
import 'sesion/recuperacion.dart';
import 'sesion/sesion.dart';
import 'tema/tema.dart';

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
  late final _recuperacion = Recuperacion(widget.api);
  late final _sedes = Sedes(api: widget.api, sesion: widget.sesion);
  late final _espacios = Espacios(api: widget.api, sesion: widget.sesion);
  late final _horarios = Horarios(api: widget.api, sesion: widget.sesion);
  late final _reservas = Reservas(api: widget.api, sesion: widget.sesion);
  late final _historialAdmin = HistorialDeReservas(
    api: widget.api,
    sesion: widget.sesion,
  );
  final _pendiente = ReservaPendiente<Eleccion>();
  final _filtrosPendientes = FiltrosDePanelPendientes();

  StreamSubscription<AvisoTocado>? _alTocarUnAviso;

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
      (aviso) => _rutas.go(aviso.ruta),
    );
    unawaited(
      centro.abiertaPor().then((aviso) {
        if (aviso != null) {
          _rutas.go(aviso.ruta);
        }
      }),
    );
  }

  late final GoRouter _rutas = Rutas(
    api: widget.api,
    sesion: widget.sesion,
    apariencia: widget.apariencia,
    centro: widget.centro,
    recuperacion: _recuperacion,
    sedes: _sedes,
    espacios: _espacios,
    horarios: _horarios,
    reservas: _reservas,
    historialAdmin: _historialAdmin,
    pendiente: _pendiente,
    filtrosPendientes: _filtrosPendientes,
  ).router(navegador: _navegador, inicio: widget.inicio);

  @override
  void dispose() {
    unawaited(_alTocarUnAviso?.cancel());
    widget.centro?.dispose();
    widget.api.cerrar();
    _sedes.dispose();
    _espacios.dispose();
    _reservas.dispose();
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
