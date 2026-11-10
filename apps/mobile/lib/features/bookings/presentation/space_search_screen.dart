// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/calendar.dart';
import '../../../common/clock.dart';
import '../../../common/date_format.dart';
import '../../../common/dates.dart';
import '../../../common/empty_state.dart';
import '../../../common/selector.dart';
import '../../../common/text_field.dart';
import '../../../common/top_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/theme.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/space_card.dart';
import '../../venues/presentation/venues.dart';
import '../data/api_errors.dart';
import '../data/availability_api.dart';
import '../domain/availability_exceptions.dart';
import '../domain/search_rules.dart';
import 'covered_filter.dart';
import 'search_error_card.dart';
import 'search_problem_texts.dart';
import 'search_time_range.dart';
import 'space_search_bar.dart';
import 'space_search_skeleton.dart';

/// «Consultar canchas»: the courts of a venue and a sport that are free over a whole
/// range of a day. Querying books nothing; each court leads to its times with the chosen
/// range.
class SpaceSearchScreen extends StatefulWidget {
  const SpaceSearchScreen({
    super.key,
    required this.venues,
    required this.spaces,
    required this.availability,
    required this.session,
    this.sport,
  });

  final Venues venues;
  final Spaces spaces;
  final AvailabilityApi availability;
  final Session session;

  /// The sport the form opens with, the one that was tapped on the home.
  final String? sport;

  @override
  State<SpaceSearchScreen> createState() => _SpaceSearchScreenState();
}

/// What was queried, for the header and to continue to the times.
typedef _Query = ({
  Venue venue,
  String sport,
  String? kind,
  DateTime date,
  int from,
  int to,
});

class _SpaceSearchScreenState extends State<SpaceSearchScreen> {
  (List<Venue>, Catalog)? _options;
  bool _loadFailed = false;

  Venue? _venue;
  String? _sport;
  String? _kind;
  final _date = TextEditingController();

  /// The text of «FECHA» the last time it changed: the controller also notifies when the
  /// cursor or the focus change, and that is not a change of the filter.
  String _dateText = '';
  int _from = 18;
  int _to = 19;

  /// Errors the API returned for the last queried range.
  Map<String, String> _rejection = const {};

  bool _searching = false;
  _Query? _query;
  List<Space>? _result;
  Object? _searchFailure;
  bool? _indoor;

  @override
  void initState() {
    super.initState();
    _sport = widget.sport;
    _date.addListener(_onDateTyped);
    _load();
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadFailed = false);
    Object? failure;
    var vencida = false;
    try {
      final venues = await widget.venues.repository.active();
      final catalog = await widget.spaces.repository.catalog();
      if (mounted) setState(() => _options = (venues, catalog));
      return;
    } on SessionExpired {
      vencida = true;
    } on NetworkFailure catch (e) {
      failure = e;
    }
    if (!mounted) return;
    setState(() => _loadFailed = true);
    await notifySendFailure(
      context,
      session: widget.session,
      expired: vencida,
      error: failure,
      retry: _load,
    );
  }

  void _onDateTyped() {
    if (_date.text == _dateText) return;
    _dateText = _date.text;
    _onFilterChanged();
  }

  DateTime? get _day => switch (readDate(_date.text)) {
    final d? => DateTime.utc(d.year, d.month, d.day),
    null => null,
  };

  /// The errors of the filters that can already be judged: a complete date that does not
  /// exist, the date outside the next days, and the rules of the range when there is a
  /// venue.
  Map<String, String> get _errors {
    final l = AppLocalizations.of(context);
    final errors = <String, String>{};
    final day = _day;
    if (_date.text.length >= l.spaceSearchDatePlaceholder.length &&
        day == null) {
      errors['date'] = l.spaceSearchDateFormat;
    }
    final venue = _venue;
    final problems = <String, RangeProblem>{
      if (day != null && venue == null) ...dateErrors(day: day, now: clubNow()),
      if (venue != null && day != null)
        ...rangeErrors(
          venue: venue,
          day: day,
          from: _from,
          to: _to,
          now: clubNow(),
        ),
    };
    errors.addAll({
      for (final e in problems.entries) e.key: rangeProblemText(l, e.value),
    });
    return {...errors, ..._rejection};
  }

  bool get _isComplete =>
      _venue != null && _sport != null && _day != null && _errors.isEmpty;

  /// Another filter is no longer the search that is seen: the result is removed until
  /// queried again, so as not to show courts of another query as if they were of this
  /// one.
  void _onFilterChanged() {
    setState(() {
      _rejection = const {};
      _query = null;
      _result = null;
      _searchFailure = null;
      _indoor = null;
    });
  }

  void _applyChange(VoidCallback change) {
    change();
    _onFilterChanged();
  }

  Future<void> _search() async {
    final venue = _venue;
    final sport = _sport;
    final day = _day;
    if (venue == null || sport == null || day == null) return;
    if (!_isComplete || _searching) return;
    final query = (
      venue: venue,
      sport: sport,
      kind: _kind,
      date: day,
      from: _from,
      to: _to,
    );
    setState(() {
      _searching = true;
      _result = null;
      _searchFailure = null;
      _indoor = null;
    });
    var vencida = false;
    try {
      final free = await widget.availability.freeSpaces(
        venueId: venue.id,
        sport: sport,
        kind: _kind,
        date: day,
        from: hhmm(_from),
        to: hhmm(_to),
      );
      if (!mounted) return;
      setState(() {
        _searching = false;
        _query = query;
        _result = free;
      });
      return;
    } on RangeRejected catch (e) {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _rejection = e.errors;
      });
      if (e.errors.containsKey('venue_id')) {
        widget.venues.notifyChange();
        await _load();
      }
      return;
    } on SessionExpired {
      vencida = true;
    } on NetworkFailure catch (e) {
      _searchFailure = e;
    }
    if (!mounted) return;
    setState(() {
      _searching = false;
      _query = query;
    });
    if (vencida) await notifySessionExpired(context, widget.session);
  }

  void _clear() {
    _date.clear();
    _applyChange(() {
      _venue = null;
      _sport = null;
      _kind = null;
      _from = 18;
      _to = 19;
    });
  }

  Future<void> _selectVenue(List<Venue> venues) async {
    final chosen = await pickOption<Venue>(
      context,
      title: AppLocalizations.of(context).spaceSearchVenue,
      options: [
        for (final s in venues)
          if (s.spaceCount > 0) (s, s.name),
      ],
      selected: _venue,
    );
    if (chosen == null || !mounted || chosen.id == _venue?.id) return;
    _applyChange(() {
      _venue = chosen;
      // The new venue may not have that sport.
      if (!chosen.sports.contains(_sport)) {
        _sport = null;
        _kind = null;
      }
    });
  }

  Future<void> _selectSport(Catalog catalog) async {
    final selected = await pickOption<String>(
      context,
      title: AppLocalizations.of(context).spaceSearchSport,
      options: [
        for (final d in catalog.sports)
          if (_venue?.sports.contains(d.key) ?? true) (d.key, d.name),
      ],
      selected: _sport,
    );
    if (selected != null && mounted && selected != _sport) {
      _applyChange(() {
        _sport = selected;
        _kind = null;
      });
    }
  }

  Future<void> _selectKind(Catalog catalog) async {
    final sport = catalog.sport(_sport ?? '');
    if (sport == null) return;
    const all = '';
    final selected = await pickOption<String>(
      context,
      title: AppLocalizations.of(context).spaceSearchKind,
      options: [
        (all, AppLocalizations.of(context).spaceSearchAllKinds),
        for (final t in sport.kinds) (t.key, t.name),
      ],
      selected: _kind ?? all,
    );
    final kind = selected == all ? null : selected;
    if (selected != null && mounted && kind != _kind) {
      _applyChange(() => _kind = kind);
    }
  }

  Future<void> _selectTime({required bool start}) async {
    final hours = start
        ? [for (var h = 0; h < 24; h++) h]
        : [for (var h = 1; h < 24; h++) h, 0];
    final chosen = await pickOption<int>(
      context,
      title: start
          ? AppLocalizations.of(context).spaceSearchFrom
          : AppLocalizations.of(context).spaceSearchTo,
      options: [for (final h in hours) (h, hhmm(h))],
      selected: start ? _from : _to,
      columns: 3,
    );
    if (chosen == null || !mounted) return;
    if (chosen == (start ? _from : _to)) return;
    _applyChange(() {
      if (start) {
        _from = chosen;
      } else {
        _to = chosen;
      }
    });
  }

  Future<void> _selectDate() async {
    final now = clubNow();
    final chosen = await pickUpcomingDay(
      context,
      today: DateTime(now.year, now.month, now.day),
      days: daysInView,
      proposed: _day,
    );
    if (chosen != null && mounted) _date.text = formatDate(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final options = _options;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: TopBar(
        title: AppLocalizations.of(context).spaceSearchTitle,
        onBack: () => context.go('/home'),
      ),
      bottomNavigationBar: options == null
          ? null
          : SpaceSearchBar(
              onClear: _searching ? null : _clear,
              onSearch: _isComplete && !_searching ? _search : null,
              searching: _searching,
            ),
      body: options == null ? _bodyWithoutOptions() : _form(options, p),
    );
  }

  Widget _bodyWithoutOptions() => _loadFailed
      ? Center(
          child: TextActionButton(
            label: AppLocalizations.of(context).bookingRetry,
            onTap: _load,
          ),
        )
      : SpaceSearchSkeleton(header: _header(_intro));

  Widget _header(String subtitle) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.spaceSearchHeading,
            style: Texts.h1.copyWith(color: p.textPrimary),
          ),
        ),
        const SizedBox(height: Spacing.s4),
        Text(subtitle, style: Texts.body.copyWith(color: p.textSecondary)),
      ],
    );
  }

  Widget _form((List<Venue>, Catalog) options, Palette p) =>
      SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.s24,
          Spacing.s8,
          Spacing.s24,
          Spacing.s40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(_subtitle(options.$2)),
            if (_searchFailure case final failure?) ...[
              const SizedBox(height: Spacing.s16),
              SearchErrorCard(
                noConnection: failure is NoConnection,
                onBack: () => setState(() {
                  _searchFailure = null;
                  _query = null;
                }),
                onRetry: _search,
              ),
            ],
            const SizedBox(height: Spacing.s16),
            ..._filters(options.$1, options.$2),
            if (_searching) const SpaceResultsSkeleton(),
            if ((_query, _result) case (final query?, final result?))
              ..._results(query, result, options.$2, p),
          ],
        ),
      );

  String get _intro =>
      AppLocalizations.of(context).spaceSearchIntro(maxHours, minHours);

  String _subtitle(Catalog catalog) {
    final c = _query;
    if (c == null) return _intro;
    return AppLocalizations.of(context).spaceSearchSubtitle(
      shortDate(c.date),
      hhmm(c.from),
      hhmm(c.to),
      c.venue.name,
      _searchedFor(c, catalog),
    );
  }

  String _searchedFor(_Query c, Catalog catalog) {
    final kind = c.kind;
    return kind == null
        ? catalog.sport(c.sport)?.name ?? c.sport
        : catalog.shortKind(c.sport, kind);
  }

  List<Widget> _filters(List<Venue> venues, Catalog catalog) {
    final l = AppLocalizations.of(context);
    final errors = _errors;
    final sport = catalog.sport(_sport ?? '');
    final kind = _kind;
    return [
      SelectorField(
        label: l.spaceSearchVenue.toUpperCase(),
        semanticLabel: l.spaceSearchVenue,
        value: _venue?.name,
        placeholder: l.spaceSearchPickVenue,
        icon: Icons.expand_more_rounded,
        onTap: _searching ? null : () => _selectVenue(venues),
        error: errors['venue_id'],
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: l.spaceSearchSport.toUpperCase(),
        semanticLabel: l.spaceSearchSport,
        value: sport?.name,
        placeholder: l.spaceSearchPickSport,
        icon: Icons.expand_more_rounded,
        onTap: _searching ? null : () => _selectSport(catalog),
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: l.spaceSearchKind.toUpperCase(),
        semanticLabel: l.spaceSearchKind,
        value: sport == null
            ? null
            : kind == null
            ? l.spaceSearchAllKinds
            : catalog.shortKind(sport.key, kind),
        placeholder: l.spaceSearchAllKinds,
        icon: Icons.expand_more_rounded,
        onTap: sport == null || _searching ? null : () => _selectKind(catalog),
      ),
      const SizedBox(height: Spacing.s12),
      FormTextField(
        label: l.spaceSearchDate.toUpperCase(),
        semanticLabel: l.spaceSearchDate,
        controller: _date,
        placeholder: l.spaceSearchDatePlaceholder,
        error: errors['date'],
        keyboardType: TextInputType.number,
        inputFormatters: const [DateInputFormatter()],
        enabled: !_searching,
        trailing: IconButton(
          tooltip: l.spaceSearchPickDate,
          onPressed: _searching ? null : _selectDate,
          icon: Icon(
            Icons.calendar_today_outlined,
            color: context.palette.textSecondary,
          ),
        ),
      ),
      const SizedBox(height: Spacing.s12),
      SearchTimeRange(
        from: _from,
        to: _to,
        fromError: errors['start_hour'],
        toError: errors['until'],
        onPickFrom: _searching ? null : () => _selectTime(start: true),
        onPickTo: _searching ? null : () => _selectTime(start: false),
      ),
    ];
  }

  List<Widget> _results(
    _Query query,
    List<Space> result,
    Catalog catalog,
    Palette p,
  ) {
    final l = AppLocalizations.of(context);
    final indoor = _indoor;
    final views = [
      for (final c in result)
        if (indoor == null || c.covered == indoor) c,
    ];
    final range = '${hhmm(query.from)} – ${hhmm(query.to)}';
    final criteria = _searchedFor(query, catalog).toUpperCase();
    final header = result.isEmpty
        ? l.spaceSearchNoAvailability(range, criteria)
        : l.spaceSearchResults(result.length, range, criteria);
    final outdoor = result.where((c) => !c.covered).length;
    return [
      const SizedBox(height: Spacing.s24),
      if (result.isNotEmpty) ...[
        CoveredFilter(
          total: result.length,
          outdoor: outdoor,
          chosen: indoor,
          onSelect: (value) => setState(() => _indoor = value),
        ),
        const SizedBox(height: Spacing.s12),
      ],
      Semantics(
        liveRegion: true,
        child: Text(header, style: Texts.overline.copyWith(color: p.accentInk)),
      ),
      const SizedBox(height: Spacing.s12),
      if (result.isEmpty)
        EmptyState(
          title: l.spaceSearchEmptyTitle,
          text: l.spaceSearchEmptyText,
          action: l.spaceSearchClearFilters,
          onTap: _clear,
        ),
      for (final space in views) ...[
        SpaceCard(
          space: space,
          catalog: catalog,
          onBook: () => _toAvailability(query, space),
        ),
        const SizedBox(height: Spacing.s16),
      ],
    ];
  }

  void _toAvailability(_Query query, Space space) {
    final end = query.to == 0 ? 24 : query.to;
    final route = Uri(
      path: '/venues/${query.venue.id}/spaces/${space.id}',
      queryParameters: {
        'date': isoDate(query.date),
        'hours': '${end - query.from}',
        'start': hhmm(query.from),
      },
    );
    // On top of the search: on returning, the filters and the result are still there.
    context.push(route.toString());
  }
}
