import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../common/button.dart';
import '../../../common/dates.dart';
import '../../../common/day_timeline.dart';
import '../../../common/empty_state.dart';
import '../../../common/error_dialog.dart';
import '../../../common/motion.dart';
import '../../../common/skeleton.dart';
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
    required this.sedeId,
    required this.espacioId,
    required this.venues,
    required this.espacios,
    required this.horarios,
    required this.sesion,
    this.date,
    this.hours,
    this.start,
    this.modificando,
    this.volverA = 'Mis reservas',
  });

  final String sedeId;
  final String espacioId;
  final Venues venues;
  final Spaces espacios;
  final AvailabilityApi horarios;
  final Session sesion;

  /// Lo que ya viene elegido desde la consulta de canchas: el día, la duración y la hora
  /// de inicio (`HH:MM`). La hora queda elegida si está disponible.
  final DateTime? date;
  final int? hours;
  final String? start;

  /// La reserva que se está modificando: se mantiene su duración, su franja se ve libre y
  /// marcada, y CONTINUAR CON EL CAMBIO lleva a «Confirmá el cambio».
  final Booking? modificando;

  /// Cómo se llama la pantalla a la que vuelve la modificación.
  final String volverA;

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  (Venue, List<Space>, Catalog)? _datos;
  late String _elegida = widget.espacioId;
  late DateTime? _fecha = switch (widget.modificando) {
    final r? => _diaDe(r.startsAt),
    null => widget.date,
  };
  late int _horas = switch ((widget.modificando, widget.hours)) {
    (final r?, _) => r.endsAt.difference(r.startsAt).inHours,
    (_, final h?) when h >= minHours && h <= maxHours => h,
    _ => minHours,
  };
  AvailabilityGrid? _grilla;

  /// La cancha y la duración con que se pidió la grilla que está en pantalla: mientras
  /// llega otra, el resumen y la nota siguen hablando de esa.
  (String, int)? _deLaGrilla;

  /// El día de hoy en el club, según la última grilla: FECHA sigue a la vista aunque la
  /// consulta siguiente falle.
  DateTime? _hoy;
  late String? _inicio = switch (widget.modificando) {
    final r? => shortTime(r.startsAt),
    null => widget.start,
  };
  bool _consultando = false;
  bool _fallo = false;

  /// La cancha ya no está y se está avisando: no queda nada cargando detrás del aviso.
  bool _cambio = false;

  /// Sube con cada consulta: la respuesta de una que ya no es la última se descarta.
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Space? get _cancha => _datos?.$2.where((c) => c.id == _elegida).firstOrNull;

  /// La franja de [inicio] en la cancha y el día elegidos es la de la reserva que se
  /// modifica.
  bool _esLaActual(String start) => switch (widget.modificando) {
    final r? =>
      r.spaceId == _elegida &&
          _fecha == _diaDe(r.startsAt) &&
          start == shortTime(r.startsAt),
    null => false,
  };

  bool get _puedeSeguir {
    final start = _inicio;
    return start != null && !_consultando && !_esLaActual(start);
  }

  Future<void> _cargar() async {
    setState(() => _fallo = false);
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.repository.catalog();
      final venues = await widget.venues.repository.active();
      final venue = venues.where((s) => s.id == widget.sedeId).firstOrNull;
      final canchas = await widget.espacios.repository.active(
        venueId: widget.sedeId,
      );
      final elegida = canchas
          .where((c) => c.id == widget.espacioId)
          .firstOrNull;
      if (!mounted) return;
      if (venue == null || elegida == null) {
        await _yaNoEsta(venue == null);
        return;
      }
      setState(() {
        _datos = (
          venue,
          [
            for (final c in canchas)
              if (c.sport == elegida.sport && c.kind == elegida.kind) c,
          ],
          catalogo,
        );
      });
      await _consultar();
      return;
    } on SessionExpired {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    await _avisar(vencida: vencida, fallo: fallo, reintentar: _cargar);
  }

  /// Pide la grilla de la cancha, la fecha y la duración elegidas. La hora de inicio
  /// elegida queda si sigue disponible.
  Future<void> _consultar() async {
    final request = ++_pedido;
    setState(() {
      _consultando = true;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    final consulta = (_elegida, _horas);
    try {
      final grilla = await widget.horarios.grid(
        _elegida,
        date: _fecha,
        hours: _horas,
        bookingId: widget.modificando?.id,
      );
      if (!mounted || request != _pedido) return;
      setState(() {
        _consultando = false;
        _grilla = grilla;
        _deLaGrilla = consulta;
        _hoy = grilla.today;
        _fecha = grilla.date;
        final sigue = grilla.slots.any(
          (f) => f.start == _inicio && f.available,
        );
        if (!sigue) _inicio = null;
      });
      return;
    } on SpaceUnavailable {
      if (mounted && request == _pedido) await _yaNoEsta(false);
      return;
    } on DateExpired {
      // El día elegido ya pasó (la pantalla quedó abierta de un día para otro): vuelve a hoy.
      if (!mounted || request != _pedido || _fecha == null) return;
      _fecha = null;
      _inicio = null;
      await _consultar();
      return;
    } on SessionExpired {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted || request != _pedido) return;
    setState(() {
      _consultando = false;
      _grilla = null;
      _deLaGrilla = null;
      _inicio = null;
    });
    await _avisar(vencida: vencida, fallo: fallo, reintentar: _consultar);
  }

  /// Un error de la API: sin horarios en pantalla y REINTENTAR, salvo que la persona
  /// reintente desde el aviso.
  Future<void> _avisar({
    required bool vencida,
    required Object? fallo,
    required Future<void> Function() reintentar,
  }) async {
    if (!mounted) return;
    setState(() => _fallo = true);
    await avisarFalloDeCarga(
      context,
      session: widget.sesion,
      expired: vencida,
      error: fallo,
      reintentar: reintentar,
    );
  }

  Future<void> _yaNoEsta(bool laSede) async {
    setState(() {
      _consultando = false;
      _cambio = true;
    });
    // La reserva que se modifica ya no se puede pasar a esta cancha: vuelve a Mis reservas.
    if (widget.modificando != null) {
      await showChangedMeanwhile(context);
      if (mounted) _salir(ModifyResult.cambio);
      return;
    }
    await showChangedMeanwhile(context);
    if (!mounted) return;
    if (laSede) {
      widget.venues.notifyChange();
    } else {
      widget.espacios.notifyChange();
    }
    context.go(laSede ? '/sedes' : '/sedes/${widget.sedeId}');
  }

  void _elegirCancha(String id) {
    if (id == _elegida) return;
    setState(() => _elegida = id);
    _consultar();
  }

  void _elegirFecha(DateTime dia) {
    if (dia == _fecha) return;
    setState(() => _fecha = dia);
    _consultar();
  }

  void _cambiarHoras(int hours) {
    setState(() => _horas = hours);
    _consultar();
  }

  Future<void> _continuar() async {
    final data = _datos;
    final cancha = _cancha;
    final date = _fecha;
    final franja = _grilla?.slots.where((f) => f.start == _inicio).firstOrNull;
    if (data == null || cancha == null || date == null || franja == null) {
      return;
    }
    final eleccion = BookingChoice(
      venue: data.$1,
      space: cancha,
      kind: data.$3.shortKind(cancha.sport, cancha.kind),
      date: date,
      start: franja.start,
      end: franja.end,
      hours: _horas,
    );
    if (widget.modificando case final booking?) {
      final resultado = await context.push<ModifyResult>(
        '/reservas/${booking.id}/modificar/confirmar',
        extra: (booking, eleccion),
      );
      if (!mounted) return;
      if (resultado == ModifyResult.ocupado) {
        setState(() => _inicio = null);
        await _consultar();
      } else if (resultado != null) {
        _salir(resultado);
      }
      return;
    }
    final resultado = await context.push<ConfirmResult>(
      '/sedes/${widget.sedeId}/canchas/${widget.espacioId}/reservar',
      extra: eleccion,
    );
    if (resultado == ConfirmResult.ocupado && mounted) {
      setState(() => _inicio = null);
      await _consultar();
    }
  }

  /// Vuelve a la pantalla de la que vino con cómo terminó la modificación.
  void _salir([ModifyResult? resultado]) {
    if (context.canPop()) {
      context.pop(resultado);
    } else {
      context.go('/reservas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = _datos;
    final cancha = _cancha;
    final modificando = widget.modificando;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: data == null
          ? null
          : AvailabilityActionBar(
              texto: modificando == null
                  ? 'CONTINUAR'
                  : 'CONTINUAR CON EL CAMBIO',
              alContinuar: _puedeSeguir ? _continuar : null,
            ),
      body: data == null || cancha == null
          ? SafeArea(
              child: _cambio
                  ? const SizedBox.shrink()
                  : _fallo
                  ? Center(
                      child: TextActionButton(
                        label: 'REINTENTAR',
                        onTap: _cargar,
                      ),
                    )
                  : const Padding(
                      padding: Spacing.listPagePadding,
                      child: SkeletonList(shape: SkeletonShape.grid, count: 6),
                    ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _portada(data, cancha),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.s24,
                      Spacing.s20,
                      Spacing.s24,
                      Spacing.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _secciones(data, cancha, p),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _secciones(
    (Venue, List<Space>, Catalog) data,
    Space cancha,
    Palette p,
  ) {
    final modificando = widget.modificando;
    return [
      if (modificando != null) ...[
        ModificationNote(reserva: modificando, horas: _horas),
        const SizedBox(height: Spacing.s24),
      ],
      SpaceSelection(
        canchas: data.$2,
        elegida: _elegida,
        alElegir: _elegirCancha,
      ),
      if (_hoy case final hoy?) ...[
        SlotsSection(
          titulo: 'FECHA',
          child: DateStrip(hoy: hoy, elegida: _fecha, alElegir: _elegirFecha),
        ),
        if (modificando == null)
          DurationSection(
            horas: _horas,
            cierre: data.$1.closing,
            alCambiar: _cambiarHoras,
          ),
      ],
      _grillaOAviso(p),
      if ((_grilla, _deLaGrilla) case (
        final grilla?,
        (final id, final hours)?,
      )) ...[
        const SizedBox(height: Spacing.s8),
        _resumen(data, cancha, grilla, id, hours),
      ],
    ];
  }

  Widget _portada((Venue, List<Space>, Catalog) data, Space cancha) {
    final modificando = widget.modificando;
    return AvailabilityCover(
      sede: data.$1,
      tipo: data.$3.shortKind(cancha.sport, cancha.kind),
      deporte: cancha.sport,
      volverA: modificando != null
          ? widget.volverA
          : widget.date == null
          ? 'Sedes'
          : 'Buscar cancha',
      alVolver: modificando != null
          ? _salir
          : () => context.canPop()
                ? context.pop()
                : context.go('/sedes/${widget.sedeId}'),
    );
  }

  Widget _resumen(
    (Venue, List<Space>, Catalog) data,
    Space cancha,
    AvailabilityGrid grilla,
    String id,
    int hours,
  ) {
    return BookingSummary(
      tipo: data.$3.shortKind(cancha.sport, cancha.kind),
      precio:
          (data.$2.where((c) => c.id == id).firstOrNull ?? cancha).pricePerHour,
      horas: hours,
      franja: grilla.slots.where((f) => f.start == _inicio).firstOrNull,
      fecha: grilla.date,
    );
  }

  Widget _grillaOAviso(Palette p) {
    final grilla = _grilla;
    final hours = _deLaGrilla?.$2 ?? _horas;
    if (grilla == null) {
      return Padding(
        padding: const EdgeInsets.all(Spacing.s24),
        child: _cambio
            ? const SizedBox.shrink()
            : _consultando || !_fallo
            ? const SkeletonList(shape: SkeletonShape.grid, count: 4)
            : Center(
                child: TextActionButton(label: 'REINTENTAR', onTap: _consultar),
              ),
      );
    }
    return SlotsSection(
      titulo: 'HORARIO DISPONIBLE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2,
            child: _consultando ? const LinearProgressIndicator() : null,
          ),
          const SizedBox(height: Spacing.s8),
          _contenidoDeLaGrilla(grilla, hours),
        ],
      ),
    );
  }

  /// Mientras llega otra grilla, la anterior queda atenuada y no se puede tocar.
  Widget _contenidoDeLaGrilla(AvailabilityGrid grilla, int hours) {
    return IgnorePointer(
      ignoring: _consultando,
      child: AnimatedOpacity(
        opacity: _consultando ? 0.5 : 1,
        duration: const Duration(milliseconds: 150),
        child: !grilla.hasFree
            ? EmptyState(
                title: 'No hay horarios disponibles',
                text: _porQueNoHay(grilla, hours),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_datos?.$1 case final venue?) ...[
                    Heartbeat(
                      trigger: _horas,
                      child: _lineaDelDia(venue, grilla, hours),
                    ),
                    const SizedBox(height: Spacing.s12),
                  ],
                  PairedGrid(
                    alto: Spacing.controlHeight,
                    hijos: [
                      for (final f in grilla.slots)
                        SlotCard(
                          franja: f,
                          actual: _esLaActual(f.start),
                          elegida: f.start == _inicio,
                          alTocar: f.available
                              ? () => setState(() => _inicio = f.start)
                              : null,
                        ),
                    ],
                  ),
                  if (grilla.unavailableCount > 0) ...[
                    const SizedBox(height: Spacing.s12),
                    AvailabilityNote(
                      texto: hours == 1
                          ? 'Algunos horarios ya están ocupados · '
                                '${grilla.unavailableCount} no disponibles'
                          : 'Con ${duration(hours)} hay menos inicios posibles · '
                                '${grilla.unavailableCount} no disponibles',
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// Una celda por hora, de la apertura a la última antes del cierre: libre si alguna
  /// franja libre la cubre, elegida si la cubre la franja elegida.
  Widget _lineaDelDia(Venue venue, AvailabilityGrid grilla, int hours) {
    int hora(String hhmm) => int.parse(hhmm.split(':').first);
    final desde = hora(venue.opening);
    final cierre = hora(venue.closing);
    final hasta = cierre == 0 ? 24 : cierre;
    bool cubre(Slot f, int h) {
      final start = hora(f.start);
      return start <= h && h < start + hours;
    }

    final elegida = grilla.slots.where((f) => f.start == _inicio);
    return DayTimeline(
      from: desde,
      slots: [
        for (var h = desde; h < hasta; h++)
          if (elegida.any((f) => cubre(f, h)))
            SlotState.chosen
          else if (grilla.slots.any((f) => f.available && cubre(f, h)))
            SlotState.free
          else
            SlotState.taken,
      ],
    );
  }

  String _porQueNoHay(AvailabilityGrid grilla, int hours) {
    if (!grilla.opens) return 'La sede no abre ese día. Probá con otra fecha.';
    if (hours > 1) {
      return 'Con ${duration(hours)} seguidas no entra ningún turno antes del '
          'cierre. Probá con una duración menor, otra fecha u otra cancha.';
    }
    return 'Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.';
  }
}

/// El día de [momento], en la hora del club.
DateTime _diaDe(DateTime momento) =>
    DateTime.utc(momento.year, momento.month, momento.day);
