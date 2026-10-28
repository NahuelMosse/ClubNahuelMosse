// kit-shape: the widget and its State are a single Flutter piece
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/bottom_bar.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venues.dart';
import '../data/booking_history_api.dart';
import '../domain/booking_history_entry.dart';
import '../domain/history_filters.dart';
import '../domain/pending_panel_filters.dart';
import 'admin_panel_body.dart';
import 'booking_filters_screen.dart';
import 'bookings_header.dart';
import 'paginated_history.dart';
import 'panel_filter_options.dart';
import 'void_booking.dart';

/// El panel de administración: el historial global de reservas (CU-14), pestaña «Reservas».
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({
    super.key,
    required this.history,
    required this.venues,
    required this.spaces,
    required this.session,
    required this.pending,
  });

  final BookingHistory history;
  final Venues venues;
  final Spaces spaces;
  final Session session;

  /// Los filtros que quedaron aplicados si la sesión venció mientras se miraba esta
  /// pantalla (FA5): se restauran una sola vez.
  final PendingPanelFilters pending;

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late HistoryFilters _filters =
      widget.pending.take() ?? const HistoryFilters();
  late final _pages = PaginatedHistory(widget.history);
  List<Venue>? _activeVenues;
  Catalog? _catalog;
  late final _search = TextEditingController(text: _filters.search ?? '');
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _pages.addListener(() => setState(() {}));
    _scroll.addListener(_onScroll);
    _search.addListener(_onType);
    _load();
    widget.spaces.repository.catalog().then((c) {
      if (mounted) setState(() => _catalog = c);
    }).ignore();
    widget.venues.repository.active().then((s) {
      if (mounted) setState(() => _activeVenues = s);
    }).ignore();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _pages.dispose();
    _search.removeListener(_onType);
    _search.dispose();
    super.dispose();
  }

  /// Filtra en vivo mientras se escribe (paso 7), con una pausa corta para no pedir una
  /// página por letra.
  void _onType() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _filters = _filters.withSearch(_search.text));
      _load();
    });
  }

  void _onScroll() {
    if (!_pages.needsMore) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      _pages.loadMore(_filters);
    }
  }

  Future<void> _load() async {
    final failure = await _pages.load(_filters);
    if (failure == null || !mounted) return;
    await avisarFalloDeCarga(
      context,
      session: widget.session,
      expired: failure.expired,
      error: failure.error,
      reintentar: _load,
      alVencer: () => widget.pending.save(_filters),
    );
  }

  void _selectStatus(BookingStatus? status) {
    if (_filters.status == status) return;
    setState(() => _filters = _filters.withStatus(status));
    _load();
  }

  void _clearFilters() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _filters = const HistoryFilters());
    _load();
  }

  Future<void> _openFilters() async {
    // Se precargan al abrir la pantalla: si el servidor falla ahora, el panel abre igual
    // con lo que ya se tenía.
    final (venues, catalog) = await panelFilterOptions(
      widget.venues,
      widget.spaces,
      activeVenues: _activeVenues,
      catalog: _catalog,
    );
    if (!mounted) return;
    setState(() {
      _activeVenues = venues;
      _catalog = catalog;
    });
    final chosen = await openBookingFilters(
      context,
      filters: _filters,
      venues: venues ?? const [],
      catalog: catalog ?? const Catalog([]),
    );
    if (chosen == null || !mounted) return;
    _debounce?.cancel();
    _search.text = chosen.search ?? '';
    setState(() => _filters = chosen);
    unawaited(_load());
  }

  Future<void> _openDetail(BookingHistoryEntry booking) async {
    await context.push<bool>(
      '/admin/reserva/${booking.id}',
      extra: (booking, _filters),
    );
    if (mounted) unawaited(_load());
  }

  /// La anulación de una reserva está en camino: el listado no responde hasta que termine.
  bool _voiding = false;

  Future<void> _void(BookingHistoryEntry booking) async {
    if (_voiding) return;
    final result = await voidBooking(
      context,
      booking: booking,
      history: widget.history,
      session: widget.session,
      filters: _filters,
      pending: widget.pending,
      submitting: (v) {
        if (mounted) setState(() => _voiding = v);
      },
    );
    if (result != VoidResult.nothing && mounted) {
      unawaited(_load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final result = _pages.result;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const AdminBar(current: AdminSection.bookings),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              BookingsHeader(
                session: widget.session,
                search: _search,
                filters: _filters,
                result: result,
                onOpenFilters: _openFilters,
                onSelectStatus: _selectStatus,
                onClearFilters: _clearFilters,
              ),
              ...adminPanelBody(
                result: result,
                failed: _pages.failed,
                loadingMore: _pages.loadingMore,
                hasFilters: _filters.hasFilters,
                bookings: _pages.bookings,
                catalog: _catalog,
                onRetry: _load,
                onClearFilters: _clearFilters,
                onTap: _openDetail,
                onVoid: _voiding ? null : _void,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
