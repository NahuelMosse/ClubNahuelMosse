// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/dates.dart';
import '../../../common/list_loading.dart';
import '../../../common/marker.dart';
import '../../../common/motion.dart';
import '../../../common/skeleton.dart';
import '../../../common/unhandled_errors.dart';
import '../../../theme/tokens.dart';
import '../../bookings/data/api_errors.dart';
import '../../bookings/domain/booking.dart';
import '../../bookings/presentation/bookings.dart';
import '../../bookings/presentation/cancel_confirmation.dart';
import '../../bookings/presentation/cancellation.dart';
import '../../bookings/presentation/my_bookings_screen.dart';
import '../../notifications/presentation/notification_center.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venues.dart';
import '../domain/tile_animation.dart';
import 'home_hero.dart';
import 'home_shortcuts.dart';
import 'home_sports.dart';
import 'next_booking.dart';

typedef _Datos = ({
  Booking? proxima,
  int cuantas,
  Catalog catalogo,
  List<Venue> venues,
});

/// El Home de quien inicia sesión como usuario: su próxima reserva, cuánto hay para
/// reservar y los atajos a lo que hace todos los días.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.sesion,
    required this.reservas,
    required this.espacios,
    required this.venues,
    this.centro,
  });

  final Session sesion;
  final Bookings reservas;
  final Spaces espacios;
  final Venues venues;

  /// Sin él no hay campana: la pantalla no avisa de notificaciones.
  final NotificationCenter? centro;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Datos? _datos;
  bool _fallo = false;

  /// Sube con cada lectura: la respuesta de una lectura que ya no vale se descarta.
  int _pedido = 0;

  /// La reserva que se está cancelando: su botón muestra que espera.
  String? _cancelando;

  /// Ya se vieron los bloques con datos: los que se vuelven a armar al recargar nacen
  /// terminados, sin repetir la entrada.
  bool _yaEntro = false;

  @override
  void initState() {
    super.initState();
    widget.reservas.addListener(_alCambiarLasReservas);
    _cargar();
  }

  @override
  void didUpdateWidget(HomeScreen anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.reservas != widget.reservas) {
      anterior.reservas.removeListener(_alCambiarLasReservas);
      widget.reservas.addListener(_alCambiarLasReservas);
    }
    if (anterior.reservas != widget.reservas ||
        anterior.espacios != widget.espacios ||
        anterior.venues != widget.venues) {
      _cargar();
    }
  }

  @override
  void dispose() {
    widget.reservas.removeListener(_alCambiarLasReservas);
    super.dispose();
  }

  /// Una reserva cambió desde otra pantalla: la próxima puede ser otra. Las que cambian
  /// desde acá se releen al terminar.
  void _alCambiarLasReservas() {
    if (_cancelando == null) _releerSinAvisar();
  }

  Future<_Datos> _leer() async {
    final catalogo = await widget.espacios.repository.catalog();
    final proximas = await widget.reservas.mine(history: false);
    final venues = await widget.venues.repository.active();
    return (
      proxima: proximas.firstOrNull,
      cuantas: proximas.length,
      catalogo: catalogo,
      venues: venues,
    );
  }

  /// Con [deCero] la pantalla se vacía mientras llega la lectura; al refrescar queda lo que
  /// había hasta que llega lo nuevo, y se quita si la lectura falla.
  Future<void> _cargar({bool deCero = true}) async {
    final request = ++_pedido;
    setState(() {
      if (deCero) _datos = null;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    try {
      final data = await _leer();
      if (mounted && request == _pedido) setState(() => _datos = data);
      return;
    } on SessionExpired {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted || request != _pedido) return;
    setState(() {
      _datos = null;
      _fallo = true;
    });
    await avisarFalloDeCarga(
      context,
      session: widget.sesion,
      expired: vencida,
      error: fallo,
      reintentar: _cargar,
    );
  }

  /// Vuelve a leer sin avisos: si no se puede, queda lo que había.
  Future<void> _releerSinAvisar() async {
    final request = ++_pedido;
    try {
      final data = await _leer();
      if (mounted && request == _pedido) setState(() => _datos = data);
    } on Exception catch (e, pila) {
      // Sin red o con el servidor caído, lo que había sigue siendo lo mejor que hay.
      logError(e, pila);
    }
  }

  /// Pide confirmación y cancela [r]. Al terminar, bien o porque la reserva ya había
  /// cambiado, el Home se vuelve a leer.
  Future<void> _cancelar(Booking r, Catalog catalogo) async {
    if (_cancelando != null) return;
    final confirmo = await confirmarCancelacion(
      context,
      textoDeCancelacion(r, catalogo),
    );
    if (!confirmo || !mounted) return;
    // Una lectura que venía en camino (deslizar para refrescar) ya no vale.
    _pedido++;
    await cancelWithNotices(
      context,
      sesion: widget.sesion,
      reservas: widget.reservas,
      reserva: r,
      marcar: (id) => setState(() => _cancelando = id),
      alCancelar: () => setState(() {
        if (_datos case final data?) {
          _datos = (
            proxima: null,
            cuantas: data.cuantas > 0 ? data.cuantas - 1 : 0,
            catalogo: data.catalogo,
            venues: data.venues,
          );
        }
        _cancelando = null;
      }),
      recargar: () => _cargar(deCero: false),
      releer: _releerSinAvisar,
    );
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee el Home de nuevo.
  Future<void> _modificar(Booking r) async {
    if (await abrirModificar(context, r, ruta: '?desde=inicio')) {
      await _releerSinAvisar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _datos;
    final proxima = data?.proxima;
    final yaEntro = _yaEntro;
    if (data != null) _yaEntro = true;
    return PopScope(
      canPop: _cancelando == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelando != null,
          child: const BottomBar(current: Section.home),
        ),
        body: AbsorbPointer(
          absorbing: _cancelando != null,
          child: RefreshIndicator(
            onRefresh: () => _cargar(deCero: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHero(
                    sesion: widget.sesion,
                    centro: widget.centro,
                    celdas: data == null ? null : _celdas(data),
                    yaEntro: yaEntro,
                  ),
                  if (data == null && !_fallo)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Spacing.s24),
                      child: SkeletonList(shape: SkeletonShape.booking),
                    ),
                  if (data == null && _fallo) ListRetry(onTap: _cargar),
                  if (data != null) ...[
                    if (proxima != null)
                      FadeIn(
                        delay: const Duration(milliseconds: 450),
                        fromY: 26,
                        alreadyEntered: yaEntro,
                        child: NextBooking(
                          reserva: proxima,
                          catalogo: data.catalogo,
                          cancelando: _cancelando == proxima.id,
                          alCancelar: _cancelando == null
                              ? () => _cancelar(proxima, data.catalogo)
                              : null,
                          alModificar: _cancelando == null
                              ? () => _modificar(proxima)
                              : null,
                        ),
                      ),
                    HomeSports(catalogo: data.catalogo, yaEntro: yaEntro),
                    HomeShortcuts(
                      primero:
                          tileEntrance + tileStep * data.catalogo.sports.length,
                      yaEntro: yaEntro,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<MarkerCell> _celdas(_Datos data) {
  final canchas = data.venues.fold(0, (total, s) => total + s.spaceCount);
  return [
    MarkerCell(figure: twoDigits(data.venues.length), label: 'SEDES'),
    MarkerCell(figure: twoDigits(canchas), label: 'CANCHAS'),
    MarkerCell(
      figure: twoDigits(data.cuantas),
      label: 'PRÓXIMAS',
      highlighted: true,
    ),
  ];
}
