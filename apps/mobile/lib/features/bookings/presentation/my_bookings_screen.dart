// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';

import '../../../common/bottom_bar.dart';
import '../../../common/dates.dart';
import '../../../common/empty_state.dart';
import '../../../common/list_loading.dart';
import '../../../common/price_format.dart';
import '../../../l10n/app_localizations.dart';
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
    required this.bookings,
    required this.spaces,
    required this.session,
    this.bookingId,
    this.inHistory = false,
  });

  final Bookings bookings;
  final Spaces spaces;
  final Session session;

  /// La reserva que se resalta y se trae a la vista, si se llegó desde un aviso.
  final String? bookingId;

  /// Abre en el historial: para los avisos de una reserva que ya no está entre las próximas.
  final bool inHistory;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late bool _history = widget.inHistory;
  (List<Booking>, Catalog)? _data;
  bool _failure = false;

  /// Sube con cada lectura: la respuesta de una pestaña que ya no se mira se descarta.
  int _request = 0;

  /// La tarjeta resaltada, para traerla a la vista.
  final _highlighted = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MyBookingsScreen previous) {
    super.didUpdateWidget(previous);
    if (widget.bookingId == previous.bookingId &&
        widget.inHistory == previous.inHistory) {
      return;
    }
    // Un aviso nuevo con la pantalla ya abierta: se va a la pestaña del aviso y se lee de nuevo.
    if (_history != widget.inHistory) {
      setState(() => _history = widget.inHistory);
      _load();
    } else {
      _load(fromScratch: false);
    }
  }

  void _scrollIntoView() {
    if (widget.bookingId == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final card = _highlighted.currentContext;
      if (mounted && card != null) {
        Scrollable.ensureVisible(card, alignment: 0.1);
      }
    });
  }

  /// Con [fromScratch] (otra pestaña) la lista se vacía mientras llega la nueva; al refrescar
  /// queda la que había hasta que llega la nueva, y se quita si la lectura falla.
  Future<void> _load({bool fromScratch = true}) async {
    final request = ++_request;
    setState(() {
      if (fromScratch) _data = null;
      _failure = false;
    });
    Object? failure;
    var vencida = false;
    try {
      final catalog = await widget.spaces.repository.catalog();
      final items = await widget.bookings.mine(history: _history);
      if (mounted && request == _request) {
        setState(() => _data = (items, catalog));
        _scrollIntoView();
      }
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

  /// La reserva que se está cancelando: su botón muestra que espera y los demás quedan
  /// deshabilitados.
  String? _cancelling;

  /// Pide confirmación y cancela [r]. Al terminar, bien o porque la reserva ya había
  /// cambiado, la lista se vuelve a leer.
  Future<void> _cancel(Booking r, Catalog catalog) async {
    if (_cancelling != null) return;
    final confirmed = await confirmCancellation(
      context,
      cancellationText(AppLocalizations.of(context), r, catalog),
    );
    if (!confirmed || !mounted) return;
    await cancelWithNotices(
      context,
      session: widget.session,
      bookings: widget.bookings,
      booking: r,
      toleratesOutage: true,
      mark: (id) => setState(() => _cancelling = id),
      // Sale de Próximas ya, así no se puede tocar de nuevo mientras llega la lista.
      onCancel: () => setState(() {
        if (_data case (final items, final catalog)) {
          _data = ([...items.where((x) => x.id != r.id)], catalog);
        }
        _cancelling = null;
      }),
      reload: () => _load(fromScratch: false),
      reread: _reloadQuietly,
    );
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee la lista de nuevo.
  Future<void> _modify(Booking r) async {
    if (await openModify(context, r)) await _reloadQuietly();
  }

  /// Vuelve a leer la lista sin avisos: si no se puede, queda la que había.
  Future<void> _reloadQuietly() async {
    final request = ++_request;
    try {
      final items = await widget.bookings.mine(history: _history);
      final catalog = await widget.spaces.repository.catalog();
      if (mounted && request == _request) {
        setState(() => _data = (items, catalog));
      }
    } on Exception {
      // Sin red o con el servidor caído, la lista vieja sigue siendo lo mejor que hay.
    }
  }

  void _select(bool history) {
    if (history == _history) return;
    setState(() => _history = history);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final data = _data;
    return PopScope(
      canPop: _cancelling == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelling != null,
          child: const BottomBar(current: Section.bookings),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _load(fromScratch: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Spacing.listPagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MyBookingsHeader(session: widget.session),
                  const SizedBox(height: Spacing.s16),
                  BookingsTabBar(history: _history, onSelect: _select),
                  const SizedBox(height: Spacing.s16),
                  ListSwitcher(
                    child: Column(
                      key: ValueKey((data == null, _failure, _history)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (data == null && !_failure)
                          const BookingCardSkeletons(),
                        if (data == null && _failure) ListRetry(onTap: _load),
                        if (data != null && data.$1.isEmpty)
                          EmptyState(
                            title: _history
                                ? l.bookingNoPastTitle
                                : l.bookingNoUpcomingTitle,
                            text: _history
                                ? l.bookingNoPastText
                                : l.bookingNoUpcomingText,
                          ),
                        if (data != null)
                          for (final r in data.$1) ...[
                            BookingCard(
                              booking: r,
                              catalog: data.$2,
                              key: r.id == widget.bookingId
                                  ? _highlighted
                                  : null,
                              highlighted: r.id == widget.bookingId,
                              cancelable: !_history && r.cancelable,
                              cancelling: _cancelling == r.id,
                              onCancel: _cancelling == null
                                  ? () => _cancel(r, data.$2)
                                  : null,
                              onModify: _cancelling == null
                                  ? () => _modify(r)
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
String cancellationText(AppLocalizations l, Booking r, Catalog catalog) =>
    l.bookingCancelNotice(
      shortDay(r.startsAt),
      catalog.shortKind(r.sport, r.kind),
      formatPesos(r.total),
      scheduleOf(r),
      r.venue,
    );
