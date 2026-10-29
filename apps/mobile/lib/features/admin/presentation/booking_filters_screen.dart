// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
// kit-shape: the widget and its State are a single Flutter piece
import 'package:flutter/material.dart';

import '../../../common/date_format.dart';
import '../../../common/transitions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../bookings/domain/booking_status.dart';
import '../../spaces/domain/space.dart';
import '../../venues/domain/venue.dart';
import '../domain/history_filters.dart';
import 'filter_actions.dart';
import 'filter_date_range.dart';
import 'filter_title.dart';
import 'filters_header.dart';
import 'sport_filter.dart';
import 'status_filter.dart';
import 'venue_filter.dart';

/// El panel de Filtros del historial global (CU-14, paso 5): sede, deporte, estado y rango
/// de fechas, más el buscador. Abre con lo ya aplicado y sólo devuelve algo al confirmar.
Future<HistoryFilters?> openBookingFilters(
  BuildContext context, {
  required HistoryFilters filters,
  required List<Venue> venues,
  required Catalog catalog,
}) => Navigator.of(context).push<HistoryFilters>(
  risingRoute<HistoryFilters>(
    context,
    builder: (context) =>
        _FiltersPanel(filters: filters, venues: venues, catalog: catalog),
  ),
);

class _FiltersPanel extends StatefulWidget {
  const _FiltersPanel({
    required this.filters,
    required this.venues,
    required this.catalog,
  });

  final HistoryFilters filters;
  final List<Venue> venues;
  final Catalog catalog;

  @override
  State<_FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<_FiltersPanel> {
  late String? _venueId = widget.filters.venueId;
  late String? _sport = widget.filters.sport;
  late BookingStatus? _status = widget.filters.status;
  late String? _search = widget.filters.search;
  late final _since = TextEditingController(
    text: switch (widget.filters.since) {
      final d? => formatDate(d),
      null => '',
    },
  );
  late final _until = TextEditingController(
    text: switch (widget.filters.until) {
      final d? => formatDate(d),
      null => '',
    },
  );

  @override
  void initState() {
    super.initState();
    _since.addListener(() => setState(() {}));
    _until.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _since.dispose();
    _until.dispose();
    super.dispose();
  }

  DateTime? get _sinceDate =>
      _since.text.trim().isEmpty ? null : readDate(_since.text);
  DateTime? get _untilDate =>
      _until.text.trim().isEmpty ? null : readDate(_until.text);

  /// Hay texto en el campo y no es una fecha que exista.
  bool _isNotDate(TextEditingController c) =>
      c.text.trim().isNotEmpty && readDate(c.text) == null;

  bool get _hasInvalidDate => _isNotDate(_since) || _isNotDate(_until);

  bool get _invalidRange {
    final s = _sinceDate;
    final u = _untilDate;
    return s != null && u != null && s.isAfter(u);
  }

  void _clear() {
    setState(() {
      _venueId = null;
      _sport = null;
      _status = null;
      _since.clear();
      _until.clear();
      _search = null;
    });
  }

  void _apply() {
    if (_invalidRange || _hasInvalidDate) return;
    Navigator.of(context).pop(
      HistoryFilters(
        status: _status,
        venueId: _venueId,
        sport: _sport,
        since: _sinceDate,
        until: _untilDate,
        search: _search,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: p.bgSurfaceRaised,
      body: SafeArea(
        child: Column(
          children: [
            const FiltersHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.s24,
                  Spacing.s8,
                  Spacing.s24,
                  Spacing.s24,
                ),
                children: [
                  FilterTitle(l10n.adminVenueUpper),
                  const SizedBox(height: Spacing.s8),
                  VenueFilter(
                    venues: widget.venues,
                    selected: _venueId,
                    onSelect: (venue) => setState(
                      () => _venueId = _venueId == venue.id ? null : venue.id,
                    ),
                  ),
                  const SizedBox(height: Spacing.s20),
                  FilterTitle(l10n.adminSportUpper),
                  const SizedBox(height: Spacing.s8),
                  SportFilter(
                    sports: widget.catalog.sports,
                    selected: _sport,
                    onSelect: (sport) => setState(
                      () => _sport = _sport == sport.key ? null : sport.key,
                    ),
                  ),
                  const SizedBox(height: Spacing.s20),
                  FilterTitle(l10n.adminStatusUpper),
                  const SizedBox(height: Spacing.s8),
                  StatusFilter(
                    selected: _status,
                    onSelect: (s) => setState(
                      () => _status = s == null || _status == s ? null : s,
                    ),
                  ),
                  const SizedBox(height: Spacing.s20),
                  FilterTitle(l10n.adminDateRangeUpper),
                  const SizedBox(height: Spacing.s8),
                  // En un teléfono chico dos campos lado a lado no dejan ver la fecha
                  // entera; se apilan.
                  FilterDateRange(
                    since: _since,
                    until: _until,
                    invalidSince: _isNotDate(_since),
                    invalidUntil: _isNotDate(_until),
                    invalidRange: _invalidRange,
                  ),
                ],
              ),
            ),
            FilterActions(
              onClear: _clear,
              onApply: _invalidRange || _hasInvalidDate ? null : _apply,
            ),
          ],
        ),
      ),
    );
  }
}
