// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/dates.dart';
import '../../../common/list_loading.dart';
import '../../../common/marker.dart';
import '../../../common/motion.dart';
import '../../../common/unhandled_errors.dart';
import '../../../l10n/app_localizations.dart';
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
import 'home_skeleton.dart';
import 'home_sports.dart';
import 'next_booking.dart';

typedef _Loaded = ({
  Booking? next,
  int count,
  Catalog catalog,
  List<Venue> venues,
});

/// El Home de quien inicia sesión como usuario: su próxima reserva, cuánto hay para
/// reservar y los atajos a lo que hace todos los días.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.bookings,
    required this.spaces,
    required this.venues,
    this.center,
  });

  final Session session;
  final Bookings bookings;
  final Spaces spaces;
  final Venues venues;

  /// Sin él no hay campana: la pantalla no avisa de notificaciones.
  final NotificationCenter? center;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Loaded? _data;
  bool _failure = false;

  /// Sube con cada lectura: la respuesta de una lectura que ya no vale se descarta.
  int _request = 0;

  /// La reserva que se está cancelando: su botón muestra que espera.
  String? _cancelling;

  /// Ya se vieron los bloques con datos: los que se vuelven a armar al recargar nacen
  /// terminados, sin repetir la entrada.
  bool _alreadyEntered = false;

  @override
  void initState() {
    super.initState();
    widget.bookings.addListener(_onBookingsChanged);
    _load();
  }

  @override
  void didUpdateWidget(HomeScreen previous) {
    super.didUpdateWidget(previous);
    if (previous.bookings != widget.bookings) {
      previous.bookings.removeListener(_onBookingsChanged);
      widget.bookings.addListener(_onBookingsChanged);
    }
    if (previous.bookings != widget.bookings ||
        previous.spaces != widget.spaces ||
        previous.venues != widget.venues) {
      _load();
    }
  }

  @override
  void dispose() {
    widget.bookings.removeListener(_onBookingsChanged);
    super.dispose();
  }

  /// Una reserva cambió desde otra pantalla: la próxima puede ser otra. Las que cambian
  /// desde acá se releen al terminar.
  void _onBookingsChanged() {
    if (_cancelling == null) _reloadQuietly();
  }

  Future<_Loaded> _read() async {
    final catalog = await widget.spaces.repository.catalog();
    final upcoming = await widget.bookings.mine(history: false);
    final venues = await widget.venues.repository.active();
    return (
      next: upcoming.firstOrNull,
      count: upcoming.length,
      catalog: catalog,
      venues: venues,
    );
  }

  /// Con [fromScratch] la pantalla se vacía mientras llega la lectura; al refrescar queda lo que
  /// había hasta que llega lo nuevo, y se quita si la lectura falla.
  Future<void> _load({bool fromScratch = true}) async {
    final request = ++_request;
    setState(() {
      if (fromScratch) _data = null;
      _failure = false;
    });
    Object? failure;
    var vencida = false;
    try {
      final data = await _read();
      if (mounted && request == _request) setState(() => _data = data);
      return;
    } on SessionExpired {
      vencida = true;
    } on NetworkFailure catch (e) {
      failure = e;
    }
    if (!mounted || request != _request) return;
    setState(() {
      _data = null;
      _failure = true;
    });
    await notifyLoadFailure(
      context,
      session: widget.session,
      expired: vencida,
      error: failure,
      retry: _load,
    );
  }

  /// Vuelve a leer sin avisos: si no se puede, queda lo que había.
  Future<void> _reloadQuietly() async {
    final request = ++_request;
    try {
      final data = await _read();
      if (mounted && request == _request) setState(() => _data = data);
    } on Exception catch (e, stack) {
      // Sin red o con el servidor caído, lo que había sigue siendo lo mejor que hay.
      logError(e, stack);
    }
  }

  /// Pide confirmación y cancela [r]. Al terminar, bien o porque la reserva ya había
  /// cambiado, el Home se vuelve a leer.
  Future<void> _cancel(Booking r, Catalog catalog) async {
    if (_cancelling != null) return;
    final confirmed = await confirmCancellation(
      context,
      cancellationText(AppLocalizations.of(context), r, catalog),
    );
    if (!confirmed || !mounted) return;
    // Una lectura que venía en camino (deslizar para refrescar) ya no vale.
    _request++;
    await cancelWithNotices(
      context,
      session: widget.session,
      bookings: widget.bookings,
      booking: r,
      mark: (id) => setState(() => _cancelling = id),
      onCancel: () => setState(() {
        if (_data case final data?) {
          _data = (
            next: null,
            count: data.count > 0 ? data.count - 1 : 0,
            catalog: data.catalog,
            venues: data.venues,
          );
        }
        _cancelling = null;
      }),
      reload: () => _load(fromScratch: false),
      reread: _reloadQuietly,
    );
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee el Home de nuevo.
  Future<void> _modify(Booking r) async {
    if (await openModify(context, r, route: '?from=home')) {
      await _reloadQuietly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _data;
    final next = data?.next;
    final alreadyEntered = _alreadyEntered;
    if (data != null) _alreadyEntered = true;
    return PopScope(
      canPop: _cancelling == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelling != null,
          child: const BottomBar(current: Section.home),
        ),
        body: AbsorbPointer(
          absorbing: _cancelling != null,
          child: RefreshIndicator(
            onRefresh: () => _load(fromScratch: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHero(
                    session: widget.session,
                    center: widget.center,
                    cells: data == null
                        ? null
                        : _cells(AppLocalizations.of(context), data),
                    alreadyEntered: alreadyEntered,
                  ),
                  if (data == null && !_failure) const HomeSkeleton(),
                  if (data == null && _failure) ListRetry(onTap: _load),
                  if (data != null) ...[
                    if (next != null)
                      FadeIn(
                        delay: const Duration(milliseconds: 450),
                        fromY: 26,
                        alreadyEntered: alreadyEntered,
                        child: NextBooking(
                          booking: next,
                          catalog: data.catalog,
                          cancelling: _cancelling == next.id,
                          onCancel: _cancelling == null
                              ? () => _cancel(next, data.catalog)
                              : null,
                          onModify: _cancelling == null
                              ? () => _modify(next)
                              : null,
                        ),
                      ),
                    HomeSports(
                      catalog: data.catalog,
                      alreadyEntered: alreadyEntered,
                    ),
                    HomeShortcuts(
                      first:
                          tileEntrance + tileStep * data.catalog.sports.length,
                      alreadyEntered: alreadyEntered,
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

List<MarkerCell> _cells(AppLocalizations l10n, _Loaded data) {
  final spaceOptions = data.venues.fold(0, (total, s) => total + s.spaceCount);
  return [
    MarkerCell(
      figure: twoDigits(data.venues.length),
      label: l10n.homeMarkerVenues,
    ),
    MarkerCell(figure: twoDigits(spaceOptions), label: l10n.homeMarkerCourts),
    MarkerCell(
      figure: twoDigits(data.count),
      label: l10n.homeMarkerUpcoming,
      highlighted: true,
    ),
  ];
}
