// kit-shape: a screen or error family kept with its private parts.
// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/dates.dart';
import '../../../common/day_timeline.dart';
import '../../../common/empty_state.dart';
import '../../../common/error_dialog.dart';
import '../../../common/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/tokens.dart';
import '../../session/domain/session_exceptions.dart';
import '../../session/presentation/load_failure.dart';
import '../../session/presentation/session.dart';
import '../../spaces/domain/space.dart';
import '../../spaces/presentation/spaces.dart';
import '../../venues/domain/venue.dart';
import '../../venues/presentation/venues.dart';
import '../data/api_errors.dart';
import '../data/availability_api.dart';
import '../domain/availability_exceptions.dart';
import '../domain/availability_grid.dart';
import '../domain/booking.dart';
import '../domain/booking_choice.dart';
import '../domain/search_rules.dart';
import '../domain/slot.dart';
import 'availability_action_bar.dart';
import 'availability_cover.dart';
import 'availability_note.dart';
import 'availability_skeleton.dart';
import 'booking_summary.dart';
import 'confirm_booking_screen.dart';
import 'confirm_change_screen.dart';
import 'date_strip.dart';
import 'duration_section.dart';
import 'modification_note.dart';
import 'paired_grid.dart';
import 'slot_card.dart';
import 'slots_section.dart';
import 'space_selection.dart';

/// «Horarios disponibles» de una cancha: elige cancha de ese tipo, fecha y duración, y la
/// franja que después se confirma. Consultar no reserva nada.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({
    super.key,
    required this.venueId,
    required this.spaceId,
    required this.venues,
    required this.spaces,
    required this.availability,
    required this.session,
    this.date,
    this.hours,
    this.start,
    this.modifying,
    this.backLabel,
  });

  final String venueId;
  final String spaceId;
  final Venues venues;
  final Spaces spaces;
  final AvailabilityApi availability;
  final Session session;

  /// Lo que ya viene elegido desde la consulta de canchas: el día, la duración y la hora
  /// de inicio (`HH:MM`). La hora queda elegida si está disponible.
  final DateTime? date;
  final int? hours;
  final String? start;

  /// La reserva que se está modifying: se mantiene su duración, su franja se ve libre y
  /// marcada, y CONTINUAR CON EL CAMBIO lleva a «Confirmá el cambio».
  final Booking? modifying;

  /// Cómo se llama la pantalla a la que vuelve la modificación; «Mis reservas» si no se dice.
  final String? backLabel;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  (Venue, List<Space>, Catalog)? _data;
  late String _chosen = widget.spaceId;
  late DateTime? _date = switch (widget.modifying) {
    final r? => _dayOf(r.startsAt),
    null => widget.date,
  };
  late int _hours = switch ((widget.modifying, widget.hours)) {
    (final r?, _) => r.endsAt.difference(r.startsAt).inHours,
    (_, final h?) when h >= minHours && h <= maxHours => h,
    _ => minHours,
  };
  AvailabilityGrid? _grid;

  /// La cancha y la duración con que se pidió la grilla que está en pantalla: mientras
  /// llega otra, el resumen y la nota siguen hablando de esa.
  (String, int)? _gridQuery;

  /// El día de hoy en el club, según la última grilla: FECHA sigue a la vista aunque la
  /// consulta siguiente falle.
  DateTime? _today;
  late String? _start = switch (widget.modifying) {
    final r? => shortTime(r.startsAt),
    null => widget.start,
  };
  bool _searching = false;
  bool _failure = false;

  /// La cancha ya no está y se está avisando: no queda nada cargando detrás del aviso.
  bool _change = false;

  /// Sube con cada consulta: la respuesta de una que ya no es la última se descarta.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Space? get _space => _data?.$2.where((c) => c.id == _chosen).firstOrNull;

  /// La franja de [start] en la cancha y el día elegidos es la de la reserva que se
  /// modifica.
  bool _isCurrent(String start) => switch (widget.modifying) {
    final r? =>
      r.spaceId == _chosen &&
          _date == _dayOf(r.startsAt) &&
          start == shortTime(r.startsAt),
    null => false,
  };

  bool get _canContinue {
    final start = _start;
    return start != null && !_searching && !_isCurrent(start);
  }

  Future<void> _load() async {
    setState(() => _failure = false);
    Object? failure;
    var vencida = false;
    try {
      final catalog = await widget.spaces.repository.catalog();
      final venues = await widget.venues.repository.active();
      final venue = venues.where((s) => s.id == widget.venueId).firstOrNull;
      final spaceOptions = await widget.spaces.repository.active(
        venueId: widget.venueId,
      );
      final chosen = spaceOptions
          .where((c) => c.id == widget.spaceId)
          .firstOrNull;
      if (!mounted) return;
      if (venue == null || chosen == null) {
        await _handleGone(venue == null);
        return;
      }
      setState(() {
        _data = (
          venue,
          [
            for (final c in spaceOptions)
              if (c.sport == chosen.sport && c.kind == chosen.kind) c,
          ],
          catalog,
        );
      });
      await _search();
      return;
    } on SessionExpired {
      vencida = true;
    } on NetworkFailure catch (e) {
      failure = e;
    }
    await _notify(vencida: vencida, failure: failure, retry: _load);
  }

  /// Pide la grilla de la cancha, la fecha y la duración elegidas. La hora de inicio
  /// elegida queda si sigue disponible.
  Future<void> _search() async {
    final request = ++_request;
    setState(() {
      _searching = true;
      _failure = false;
    });
    Object? failure;
    var vencida = false;
    final query = (_chosen, _hours);
    try {
      final grid = await widget.availability.grid(
        _chosen,
        date: _date,
        hours: _hours,
        bookingId: widget.modifying?.id,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _searching = false;
        _grid = grid;
        _gridQuery = query;
        _today = grid.today;
        _date = grid.date;
        final stillOpen = grid.slots.any(
          (f) => f.start == _start && f.available,
        );
        if (!stillOpen) _start = null;
      });
      return;
    } on SpaceUnavailable {
      if (mounted && request == _request) await _handleGone(false);
      return;
    } on DateExpired {
      // El día elegido ya pasó (la pantalla quedó abierta de un día para otro): vuelve a hoy.
      if (!mounted || request != _request || _date == null) return;
      _date = null;
      _start = null;
      await _search();
      return;
    } on SessionExpired {
      vencida = true;
    } on NetworkFailure catch (e) {
      failure = e;
    }
    if (!mounted || request != _request) return;
    setState(() {
      _searching = false;
      _grid = null;
      _gridQuery = null;
      _start = null;
    });
    await _notify(vencida: vencida, failure: failure, retry: _search);
  }

  /// Un error de la API: sin horarios en pantalla y REINTENTAR, salvo que la persona
  /// reintente desde el aviso.
  Future<void> _notify({
    required bool vencida,
    required Object? failure,
    required Future<void> Function() retry,
  }) async {
    if (!mounted) return;
    setState(() => _failure = true);
    await notifyLoadFailure(
      context,
      session: widget.session,
      expired: vencida,
      error: failure,
      retry: retry,
    );
  }

  Future<void> _handleGone(bool venueGone) async {
    setState(() {
      _searching = false;
      _change = true;
    });
    // La reserva que se modifica ya no se puede pasar a esta cancha: vuelve a Mis reservas.
    if (widget.modifying != null) {
      await showChangedMeanwhile(context);
      if (mounted) _leave(ModifyResult.change);
      return;
    }
    await showChangedMeanwhile(context);
    if (!mounted) return;
    if (venueGone) {
      widget.venues.notifyChange();
    } else {
      widget.spaces.notifyChange();
    }
    context.go(venueGone ? '/venues' : '/venues/${widget.venueId}');
  }

  void _selectSpace(String id) {
    if (id == _chosen) return;
    setState(() => _chosen = id);
    _search();
  }

  void _selectDate(DateTime day) {
    if (day == _date) return;
    setState(() => _date = day);
    _search();
  }

  void _changeHours(int hours) {
    setState(() => _hours = hours);
    _search();
  }

  Future<void> _continue() async {
    final data = _data;
    final space = _space;
    final date = _date;
    final slot = _grid?.slots.where((f) => f.start == _start).firstOrNull;
    if (data == null || space == null || date == null || slot == null) {
      return;
    }
    final choice = BookingChoice(
      venue: data.$1,
      space: space,
      kind: data.$3.shortKind(space.sport, space.kind),
      date: date,
      start: slot.start,
      end: slot.end,
      hours: _hours,
    );
    if (widget.modifying case final booking?) {
      final result = await context.push<ModifyResult>(
        '/bookings/${booking.id}/modify/confirm',
        extra: (booking, choice),
      );
      if (!mounted) return;
      if (result == ModifyResult.taken) {
        setState(() => _start = null);
        await _search();
      } else if (result != null) {
        _leave(result);
      }
      return;
    }
    final result = await context.push<ConfirmResult>(
      '/venues/${widget.venueId}/spaces/${widget.spaceId}/book',
      extra: choice,
    );
    if (result == ConfirmResult.taken && mounted) {
      setState(() => _start = null);
      await _search();
    }
  }

  /// Vuelve a la pantalla de la que vino con cómo terminó la modificación.
  void _leave([ModifyResult? result]) {
    if (context.canPop()) {
      context.pop(result);
    } else {
      context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _data;
    final space = _space;
    final modifying = widget.modifying;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: data == null
          ? null
          : AvailabilityActionBar(
              text: modifying == null
                  ? l.availabilityContinue
                  : l.availabilityContinueChange,
              onContinue: _canContinue ? _continue : null,
            ),
      body: data == null || space == null
          ? _noData()
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _portada(data, space),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.s24,
                      Spacing.s20,
                      Spacing.s24,
                      Spacing.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _sections(data, space, p),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _sections(
    (Venue, List<Space>, Catalog) data,
    Space space,
    Palette p,
  ) {
    final modifying = widget.modifying;
    return [
      if (modifying != null) ...[
        ModificationNote(booking: modifying, hours: _hours),
        const SizedBox(height: Spacing.s24),
      ],
      SpaceSelection(
        spaceOptions: data.$2,
        chosen: _chosen,
        onSelect: _selectSpace,
      ),
      if (_today case final today?) ...[
        SlotsSection(
          title: AppLocalizations.of(context).availabilityDate,
          child: DateStrip(today: today, chosen: _date, onSelect: _selectDate),
        ),
        if (modifying == null)
          DurationSection(
            hours: _hours,
            closing: data.$1.closing,
            onChanged: _changeHours,
          ),
      ],
      _gridOrNotice(p),
      if ((_grid, _gridQuery) case (final grid?, (final id, final hours)?)) ...[
        const SizedBox(height: Spacing.s8),
        _summary(data, space, grid, id, hours),
      ],
    ];
  }

  Widget _noData() {
    if (_change) return const SafeArea(child: SizedBox.shrink());
    if (_failure) {
      return SafeArea(
        child: Center(
          child: TextActionButton(
            label: AppLocalizations.of(context).bookingRetry,
            onTap: _load,
          ),
        ),
      );
    }
    return AvailabilitySkeleton(backLabel: _backLabel, onBack: _onBack);
  }

  String get _backLabel {
    final l = AppLocalizations.of(context);
    if (widget.modifying != null) {
      return widget.backLabel ?? l.bookingMyBookings;
    }
    return widget.date == null ? l.venuesTitle : l.spaceSearchTitle;
  }

  VoidCallback get _onBack => widget.modifying != null
      ? _leave
      : () => context.canPop()
            ? context.pop()
            : context.go('/venues/${widget.venueId}');

  Widget _portada((Venue, List<Space>, Catalog) data, Space space) {
    return AvailabilityCover(
      venue: data.$1,
      kind: data.$3.shortKind(space.sport, space.kind),
      sport: space.sport,
      backLabel: _backLabel,
      onBack: _onBack,
    );
  }

  Widget _summary(
    (Venue, List<Space>, Catalog) data,
    Space space,
    AvailabilityGrid grid,
    String id,
    int hours,
  ) {
    return BookingSummary(
      kind: data.$3.shortKind(space.sport, space.kind),
      price:
          (data.$2.where((c) => c.id == id).firstOrNull ?? space).pricePerHour,
      hours: hours,
      slot: grid.slots.where((f) => f.start == _start).firstOrNull,
      date: grid.date,
    );
  }

  Widget _gridOrNotice(Palette p) {
    final grid = _grid;
    final hours = _gridQuery?.$2 ?? _hours;
    final l = AppLocalizations.of(context);
    if (grid == null) {
      if (_change) return const SizedBox(height: Spacing.s48);
      if (_searching || !_failure) {
        return SlotsSection(
          title: l.availabilitySlots,
          child: const Padding(
            padding: EdgeInsets.only(top: Spacing.s8 + 2),
            child: AvailabilityGridSkeleton(),
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.all(Spacing.s24),
        child: Center(
          child: TextActionButton(label: l.bookingRetry, onTap: _search),
        ),
      );
    }
    return SlotsSection(
      title: l.availabilitySlots,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2,
            child: _searching ? const LinearProgressIndicator() : null,
          ),
          const SizedBox(height: Spacing.s8),
          _gridContent(grid, hours),
        ],
      ),
    );
  }

  /// Mientras llega otra grilla, sus lugares se muestran como bloques.
  Widget _gridContent(AvailabilityGrid grid, int hours) {
    if (_searching) return const AvailabilityGridSkeleton();
    final l = AppLocalizations.of(context);
    if (!grid.hasFree) {
      return EmptyState(
        title: l.availabilityNoSlots,
        text: _emptyReason(grid, hours),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_data?.$1 case final venue?) ...[
          Heartbeat(trigger: _hours, child: _dayLine(venue, grid, hours)),
          const SizedBox(height: Spacing.s12),
        ],
        PairedGrid(
          height: Spacing.controlHeight,
          children: [
            for (final f in grid.slots)
              SlotCard(
                slot: f,
                actual: _isCurrent(f.start),
                chosen: f.start == _start,
                onTap: f.available
                    ? () => setState(() => _start = f.start)
                    : null,
              ),
          ],
        ),
        if (grid.unavailableCount > 0) ...[
          const SizedBox(height: Spacing.s12),
          AvailabilityNote(
            text: hours == 1
                ? l.availabilitySomeTaken(grid.unavailableCount)
                : l.availabilityFewerStarts(
                    grid.unavailableCount,
                    l.bookingDuration(hours),
                  ),
          ),
        ],
      ],
    );
  }

  /// Una celda por hora, de la apertura a la última antes del cierre: libre si alguna
  /// franja libre la cubre, elegida si la cubre la franja elegida.
  Widget _dayLine(Venue venue, AvailabilityGrid grid, int hours) {
    int hour(String hhmm) => int.parse(hhmm.split(':').first);
    final from = hour(venue.opening);
    final closing = hour(venue.closing);
    final to = closing == 0 ? 24 : closing;
    bool covers(Slot f, int h) {
      final start = hour(f.start);
      return start <= h && h < start + hours;
    }

    final chosen = grid.slots.where((f) => f.start == _start);
    return DayTimeline(
      from: from,
      slots: [
        for (var h = from; h < to; h++)
          if (chosen.any((f) => covers(f, h)))
            SlotState.chosen
          else if (grid.slots.any((f) => f.available && covers(f, h)))
            SlotState.free
          else
            SlotState.taken,
      ],
    );
  }

  String _emptyReason(AvailabilityGrid grid, int hours) {
    final l = AppLocalizations.of(context);
    if (!grid.opens) return l.availabilityVenueClosed;
    if (hours > 1) return l.availabilityNoFit(l.bookingDuration(hours));
    return l.availabilityNoneLeft;
  }
}

/// El día de [moment], en la hora del club.
DateTime _dayOf(DateTime moment) =>
    DateTime.utc(moment.year, moment.month, moment.day);
