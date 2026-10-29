// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/dates.dart';
import '../../../common/empty_state.dart';
import '../../../common/list_loading.dart';
import '../../../common/price_format.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../data/api_errors.dart';
import '../domain/booking.dart';
import 'booking_card.dart';
import 'booking_card_skeleton.dart';
import 'bookings.dart';
import 'bookings_tab_bar.dart';
import 'cancel_confirmation.dart';
import 'cancellation.dart';
import 'my_bookings_header.dart';

export 'booking_card.dart' show BookingCard;

/// «Mis reservas»: las próximas y el historial de quien inició sesión.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({
    super.key,
    required this.reservas,
    required this.espacios,
    required this.sesion,
    this.reservaId,
    this.enHistorial = false,
  });

  final Bookings reservas;
  final Spaces espacios;
  final Session sesion;

  /// La reserva que se resalta y se trae a la vista, si se llegó desde un aviso.
  final String? reservaId;

  /// Abre en el historial: para los avisos de una reserva que ya no está entre las próximas.
  final bool enHistorial;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late bool _historial = widget.enHistorial;
  (List<Booking>, Catalog)? _datos;
  bool _fallo = false;

  /// Sube con cada lectura: la respuesta de una pestaña que ya no se mira se descarta.
  int _pedido = 0;

  /// La tarjeta resaltada, para traerla a la vista.
  final _resaltada = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(MyBookingsScreen anterior) {
    super.didUpdateWidget(anterior);
    if (widget.reservaId == anterior.reservaId &&
        widget.enHistorial == anterior.enHistorial) {
      return;
    }
    // Un aviso nuevo con la pantalla ya abierta: se va a la pestaña del aviso y se lee de nuevo.
    if (_historial != widget.enHistorial) {
      setState(() => _historial = widget.enHistorial);
      _cargar();
    } else {
      _cargar(deCero: false);
    }
  }

  void _traerALaVista() {
    if (widget.reservaId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final card = _resaltada.currentContext;
      if (mounted && card != null) {
        Scrollable.ensureVisible(card, alignment: 0.1);
      }
    });
  }

  /// Con [deCero] (otra pestaña) la lista se vacía mientras llega la nueva; al refrescar
  /// queda la que había hasta que llega la nueva, y se quita si la lectura falla.
  Future<void> _cargar({bool deCero = true}) async {
    final request = ++_pedido;
    setState(() {
      if (deCero) _datos = null;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.repository.catalog();
      final items = await widget.reservas.mine(history: _historial);
      if (mounted && request == _pedido) {
        setState(() => _datos = (items, catalogo));
        _traerALaVista();
      }
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

  /// La reserva que se está cancelando: su botón muestra que espera y los demás quedan
  /// deshabilitados.
  String? _cancelando;

  /// Pide confirmación y cancela [r]. Al terminar, bien o porque la reserva ya había
  /// cambiado, la lista se vuelve a leer.
  Future<void> _cancelar(Booking r, Catalog catalogo) async {
    if (_cancelando != null) return;
    final confirmo = await confirmarCancelacion(
      context,
      textoDeCancelacion(r, catalogo),
    );
    if (!confirmo || !mounted) return;
    await cancelWithNotices(
      context,
      sesion: widget.sesion,
      reservas: widget.reservas,
      reserva: r,
      toleraCorte: true,
      marcar: (id) => setState(() => _cancelando = id),
      // Sale de Próximas ya, así no se puede tocar de nuevo mientras llega la lista.
      alCancelar: () => setState(() {
        if (_datos case (final items, final catalogo)) {
          _datos = ([...items.where((x) => x.id != r.id)], catalogo);
        }
        _cancelando = null;
      }),
      recargar: () => _cargar(deCero: false),
      releer: _releerSinAvisar,
    );
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee la lista de nuevo.
  Future<void> _modificar(Booking r) async {
    if (await abrirModificar(context, r)) await _releerSinAvisar();
  }

  /// Vuelve a leer la lista sin avisos: si no se puede, queda la que había.
  Future<void> _releerSinAvisar() async {
    final request = ++_pedido;
    try {
      final items = await widget.reservas.mine(history: _historial);
      final catalogo = await widget.espacios.repository.catalog();
      if (mounted && request == _pedido) {
        setState(() => _datos = (items, catalogo));
      }
    } on Exception {
      // Sin red o con el servidor caído, la lista vieja sigue siendo lo mejor que hay.
    }
  }

  void _elegir(bool historial) {
    if (historial == _historial) return;
    setState(() => _historial = historial);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _datos;
    return PopScope(
      canPop: _cancelando == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelando != null,
          child: const BottomBar(current: Section.bookings),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _cargar(deCero: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Spacing.listPagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyBookingsHeader(sesion: widget.sesion),
                  const SizedBox(height: Spacing.s16),
                  BookingsTabBar(historial: _historial, alElegir: _elegir),
                  const SizedBox(height: Spacing.s16),
                  ListSwitcher(
                    child: Column(
                      key: ValueKey((data == null, _fallo, _historial)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data == null && !_fallo)
                          const BookingCardSkeletons(),
                        if (data == null && _fallo) ListRetry(onTap: _cargar),
                        if (data != null && data.$1.isEmpty)
                          EmptyState(
                            title: _historial
                                ? 'No hay reservas pasadas'
                                : 'No hay próximas reservas',
                            text: _historial
                                ? 'No se encontraron reservas pasadas asociadas a tu cuenta.'
                                : 'No se encontraron próximas reservas asociadas a tu cuenta.',
                          ),
                        if (data != null)
                          for (final r in data.$1) ...[
                            BookingCard(
                              reserva: r,
                              catalogo: data.$2,
                              key: r.id == widget.reservaId ? _resaltada : null,
                              resaltada: r.id == widget.reservaId,
                              cancelable: !_historial && r.cancelable,
                              cancelando: _cancelando == r.id,
                              alCancelar: _cancelando == null
                                  ? () => _cancelar(r, data.$2)
                                  : null,
                              alModificar: _cancelando == null
                                  ? () => _modificar(r)
                                  : null,
                            ),
                            const SizedBox(height: Spacing.s12),
                          ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que se le pide confirmar a quien va a cancelar [r].
String textoDeCancelacion(Booking r, Catalog catalogo) =>
    '${catalogo.shortKind(r.sport, r.kind)} · ${r.venue} · '
    '${shortDay(r.startsAt)}, ${horarioDe(r)} · '
    '${formatPesos(r.total)}. El horario vuelve a quedar libre.';
