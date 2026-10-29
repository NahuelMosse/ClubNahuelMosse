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
import 'search_time_range.dart';
import 'space_search_bar.dart';
import 'space_search_skeleton.dart';

/// «Consultar canchas»: las canchas de una sede y un deporte libres en todo un rango de un
/// día. Consultar no reserva nada; cada cancha lleva a sus horarios con el rango elegido.
class SpaceSearchScreen extends StatefulWidget {
  const SpaceSearchScreen({
    super.key,
    required this.venues,
    required this.espacios,
    required this.horarios,
    required this.sesion,
    this.deporte,
  });

  final Venues venues;
  final Spaces espacios;
  final AvailabilityApi horarios;
  final Session sesion;

  /// El deporte con el que abre el formulario, el que se tocó en el inicio.
  final String? deporte;

  @override
  State<SpaceSearchScreen> createState() => _SpaceSearchScreenState();
}

/// Lo que se consultó, para el encabezado y para seguir a los horarios.
typedef _Consulta = ({
  Venue venue,
  String deporte,
  String? tipo,
  DateTime fecha,
  int desde,
  int hasta,
});

class _SpaceSearchScreenState extends State<SpaceSearchScreen> {
  (List<Venue>, Catalog)? _opciones;
  bool _falloAlCargar = false;

  Venue? _sede;
  String? _deporte;
  String? _tipo;
  final _date = TextEditingController();

  /// El texto de FECHA la última vez que cambió: el controlador avisa también cuando
  /// cambian el cursor o el foco, y eso no es cambiar el filtro.
  String _textoDeFecha = '';
  int _desde = 18;
  int _hasta = 19;

  /// Errores que devolvió la API para el último rango consultado.
  Map<String, String> _rechazo = const {};

  bool _consultando = false;
  _Consulta? _consulta;
  List<Space>? _resultado;
  Object? _falla;
  bool? _techada;

  @override
  void initState() {
    super.initState();
    _deporte = widget.deporte;
    _date.addListener(_alEscribirFecha);
    _cargar();
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _falloAlCargar = false);
    Object? fallo;
    var vencida = false;
    try {
      final venues = await widget.venues.repository.active();
      final catalogo = await widget.espacios.repository.catalog();
      if (mounted) setState(() => _opciones = (venues, catalogo));
      return;
    } on SessionExpired {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted) return;
    setState(() => _falloAlCargar = true);
    await avisarFalloDeEnvio(
      context,
      session: widget.sesion,
      expired: vencida,
      error: fallo,
      reintentar: _cargar,
    );
  }

  void _alEscribirFecha() {
    if (_date.text == _textoDeFecha) return;
    _textoDeFecha = _date.text;
    _alCambiarFiltro();
  }

  DateTime? get _dia => switch (readDate(_date.text)) {
    final d? => DateTime.utc(d.year, d.month, d.day),
    null => null,
  };

  /// Los errores de los filtros que ya se pueden juzgar: una fecha completa que no existe,
  /// la fecha fuera de los próximos días, y las reglas del rango cuando hay sede.
  Map<String, String> get _errores {
    final l = AppLocalizations.of(context);
    final errores = <String, String>{};
    final dia = _dia;
    if (_date.text.length >= l.spaceSearchDatePlaceholder.length &&
        dia == null) {
      errores['fecha'] = l.spaceSearchDateFormat;
    }
    final venue = _sede;
    final problems = <String, RangeProblem>{
      if (dia != null && venue == null) ...dateErrors(day: dia, now: clubNow()),
      if (venue != null && dia != null)
        ...rangeErrors(
          venue: venue,
          day: dia,
          from: _desde,
          to: _hasta,
          now: clubNow(),
        ),
    };
    errores.addAll({
      for (final e in problems.entries) e.key: rangeProblemText(l, e.value),
    });
    return {...errores, ..._rechazo};
  }

  bool get _completo =>
      _sede != null && _deporte != null && _dia != null && _errores.isEmpty;

  /// Otro filtro ya no es la búsqueda que se ve: el resultado se quita hasta consultar de
  /// nuevo, para no mostrar canchas de otra consulta como si fueran de ésta.
  void _alCambiarFiltro() {
    setState(() {
      _rechazo = const {};
      _consulta = null;
      _resultado = null;
      _falla = null;
      _techada = null;
    });
  }

  void _cambiar(VoidCallback cambio) {
    cambio();
    _alCambiarFiltro();
  }

  Future<void> _consultar() async {
    final venue = _sede;
    final deporte = _deporte;
    final dia = _dia;
    if (venue == null || deporte == null || dia == null) return;
    if (!_completo || _consultando) return;
    final consulta = (
      venue: venue,
      deporte: deporte,
      tipo: _tipo,
      fecha: dia,
      desde: _desde,
      hasta: _hasta,
    );
    setState(() {
      _consultando = true;
      _resultado = null;
      _falla = null;
      _techada = null;
    });
    var vencida = false;
    try {
      final libres = await widget.horarios.freeSpaces(
        venueId: venue.id,
        sport: deporte,
        kind: _tipo,
        date: dia,
        from: hhmm(_desde),
        to: hhmm(_hasta),
      );
      if (!mounted) return;
      setState(() {
        _consultando = false;
        _consulta = consulta;
        _resultado = libres;
      });
      return;
    } on RangeRejected catch (e) {
      if (!mounted) return;
      setState(() {
        _consultando = false;
        _rechazo = e.errors;
      });
      if (e.errors.containsKey('sede_id')) {
        widget.venues.notifyChange();
        await _cargar();
      }
      return;
    } on SessionExpired {
      vencida = true;
    } on FalloDeRed catch (e) {
      _falla = e;
    }
    if (!mounted) return;
    setState(() {
      _consultando = false;
      _consulta = consulta;
    });
    if (vencida) await avisarSesionVencida(context, widget.sesion);
  }

  void _limpiar() {
    _date.clear();
    _cambiar(() {
      _sede = null;
      _deporte = null;
      _tipo = null;
      _desde = 18;
      _hasta = 19;
    });
  }

  Future<void> _elegirSede(List<Venue> venues) async {
    final elegida = await pickOption<Venue>(
      context,
      title: 'Sede',
      options: [
        for (final s in venues)
          if (s.spaceCount > 0) (s, s.name),
      ],
      selected: _sede,
    );
    if (elegida == null || !mounted || elegida.id == _sede?.id) return;
    _cambiar(() {
      _sede = elegida;
      // La sede nueva puede no tener ese deporte.
      if (!elegida.sports.contains(_deporte)) {
        _deporte = null;
        _tipo = null;
      }
    });
  }

  Future<void> _elegirDeporte(Catalog catalogo) async {
    final elegido = await pickOption<String>(
      context,
      title: 'Deporte',
      options: [
        for (final d in catalogo.sports)
          if (_sede?.sports.contains(d.key) ?? true) (d.key, d.name),
      ],
      selected: _deporte,
    );
    if (elegido != null && mounted && elegido != _deporte) {
      _cambiar(() {
        _deporte = elegido;
        _tipo = null;
      });
    }
  }

  Future<void> _elegirTipo(Catalog catalogo) async {
    final deporte = catalogo.sport(_deporte ?? '');
    if (deporte == null) return;
    const todos = '';
    final elegido = await pickOption<String>(
      context,
      title: 'Tipo de cancha',
      options: [
        (todos, 'Todos los tipos'),
        for (final t in deporte.kinds) (t.key, t.name),
      ],
      selected: _tipo ?? todos,
    );
    final tipo = elegido == todos ? null : elegido;
    if (elegido != null && mounted && tipo != _tipo) {
      _cambiar(() => _tipo = tipo);
    }
  }

  Future<void> _elegirHora({required bool inicio}) async {
    final hours = inicio
        ? [for (var h = 0; h < 24; h++) h]
        : [for (var h = 1; h < 24; h++) h, 0];
    final elegida = await pickOption<int>(
      context,
      title: inicio ? 'Desde' : 'Hasta',
      options: [for (final h in hours) (h, hhmm(h))],
      selected: inicio ? _desde : _hasta,
      columns: 3,
    );
    if (elegida == null || !mounted) return;
    if (elegida == (inicio ? _desde : _hasta)) return;
    _cambiar(() {
      if (inicio) {
        _desde = elegida;
      } else {
        _hasta = elegida;
      }
    });
  }

  Future<void> _elegirFecha() async {
    final ahora = clubNow();
    final elegida = await pickUpcomingDay(
      context,
      today: DateTime(ahora.year, ahora.month, ahora.day),
      days: daysInView,
      proposed: _dia,
    );
    if (elegida != null && mounted) _date.text = formatDate(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final opciones = _opciones;
    return Scaffold(
      backgroundColor: p.bgBase,
      appBar: TopBar(
        title: 'Buscar cancha',
        onBack: () => context.go('/inicio'),
      ),
      bottomNavigationBar: opciones == null
          ? null
          : SpaceSearchBar(
              alLimpiar: _consultando ? null : _limpiar,
              alConsultar: _completo && !_consultando ? _consultar : null,
              consultando: _consultando,
            ),
      body: opciones == null ? _bodyWithoutOptions() : _form(opciones, p),
    );
  }

  Widget _bodyWithoutOptions() => _falloAlCargar
      ? Center(
          child: TextActionButton(label: 'REINTENTAR', onTap: _cargar),
        )
      : SpaceSearchSkeleton(header: _encabezado(_introduccion));

  Widget _encabezado(String subtitulo) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Consultar canchas',
            style: Texts.h1.copyWith(color: p.textPrimary),
          ),
        ),
        const SizedBox(height: Spacing.s4),
        Text(subtitulo, style: Texts.body.copyWith(color: p.textSecondary)),
      ],
    );
  }

  Widget _form((List<Venue>, Catalog) opciones, Palette p) =>
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
            _encabezado(_subtitulo(opciones.$2)),
            if (_falla case final falla?) ...[
              const SizedBox(height: Spacing.s16),
              SearchErrorCard(
                sinConexion: falla is SinConexion,
                alVolver: () => setState(() {
                  _falla = null;
                  _consulta = null;
                }),
                alReintentar: _consultar,
              ),
            ],
            const SizedBox(height: Spacing.s16),
            ..._filtros(opciones.$1, opciones.$2),
            if (_consultando) const SpaceResultsSkeleton(),
            if ((_consulta, _resultado) case (
              final consulta?,
              final resultado?,
            ))
              ..._resultados(consulta, resultado, opciones.$2, p),
          ],
        ),
      );

  static const _introduccion =
      'Elegí sede, deporte y rango horario. Solo horas completas, de '
      '$minHours a $maxHours horas.';

  String _subtitulo(Catalog catalogo) {
    final c = _consulta;
    if (c == null) return _introduccion;
    return '${c.venue.name} · ${_queSeBusco(c, catalogo)} · ${shortDate(c.fecha)} · '
        '${hhmm(c.desde)} a ${hhmm(c.hasta)}';
  }

  String _queSeBusco(_Consulta c, Catalog catalogo) {
    final tipo = c.tipo;
    return tipo == null
        ? catalogo.sport(c.deporte)?.name ?? c.deporte
        : catalogo.shortKind(c.deporte, tipo);
  }

  List<Widget> _filtros(List<Venue> venues, Catalog catalogo) {
    final errores = _errores;
    final deporte = catalogo.sport(_deporte ?? '');
    final tipo = _tipo;
    return [
      SelectorField(
        label: 'SEDE',
        semanticLabel: 'Sede',
        value: _sede?.name,
        placeholder: 'Seleccioná una sede',
        icon: Icons.expand_more_rounded,
        onTap: _consultando ? null : () => _elegirSede(venues),
        error: errores['sede_id'],
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: 'DEPORTE',
        semanticLabel: 'Deporte',
        value: deporte?.name,
        placeholder: 'Seleccioná un deporte',
        icon: Icons.expand_more_rounded,
        onTap: _consultando ? null : () => _elegirDeporte(catalogo),
      ),
      const SizedBox(height: Spacing.s12),
      SelectorField(
        label: 'TIPO DE CANCHA',
        semanticLabel: 'Tipo de cancha',
        value: deporte == null
            ? null
            : tipo == null
            ? 'Todos los tipos'
            : catalogo.shortKind(deporte.key, tipo),
        placeholder: 'Todos los tipos',
        icon: Icons.expand_more_rounded,
        onTap: deporte == null || _consultando
            ? null
            : () => _elegirTipo(catalogo),
      ),
      const SizedBox(height: Spacing.s12),
      FormTextField(
        label: 'FECHA',
        semanticLabel: 'Fecha',
        controller: _date,
        placeholder: 'DD / MM / AAAA',
        error: errores['fecha'],
        keyboardType: TextInputType.number,
        inputFormatters: const [DateInputFormatter()],
        enabled: !_consultando,
        trailing: IconButton(
          tooltip: 'Elegir la fecha en el calendario',
          onPressed: _consultando ? null : _elegirFecha,
          icon: Icon(
            Icons.calendar_today_outlined,
            color: context.palette.textSecondary,
          ),
        ),
      ),
      const SizedBox(height: Spacing.s12),
      SearchTimeRange(
        desde: _desde,
        hasta: _hasta,
        errorDesde: errores['desde'],
        errorHasta: errores['hasta'],
        alElegirDesde: _consultando ? null : () => _elegirHora(inicio: true),
        alElegirHasta: _consultando ? null : () => _elegirHora(inicio: false),
      ),
    ];
  }

  List<Widget> _resultados(
    _Consulta consulta,
    List<Space> resultado,
    Catalog catalogo,
    Palette p,
  ) {
    final techada = _techada;
    final views = [
      for (final c in resultado)
        if (techada == null || c.covered == techada) c,
    ];
    final rango = '${hhmm(consulta.desde)} – ${hhmm(consulta.hasta)}';
    final que = _queSeBusco(consulta, catalogo).toUpperCase();
    final encabezado = resultado.isEmpty
        ? 'SIN DISPONIBILIDAD · $que · $rango'
        : resultado.length == 1
        ? '1 CANCHA DISPONIBLE · $que · $rango'
        : '${resultado.length} CANCHAS DISPONIBLES · $que · $rango';
    final aireLibre = resultado.where((c) => !c.covered).length;
    return [
      const SizedBox(height: Spacing.s24),
      if (resultado.isNotEmpty) ...[
        CoveredFilter(
          total: resultado.length,
          aireLibre: aireLibre,
          elegida: techada,
          alElegir: (valor) => setState(() => _techada = valor),
        ),
        const SizedBox(height: Spacing.s12),
      ],
      Semantics(
        liveRegion: true,
        child: Text(
          encabezado,
          style: Texts.overline.copyWith(color: p.accentInk),
        ),
      ),
      const SizedBox(height: Spacing.s12),
      if (resultado.isEmpty)
        EmptyState(
          title: 'No hay canchas disponibles',
          text:
              'Ninguna cancha coincide con ese horario. Probá con otro rango o '
              'otra sede.',
          action: 'LIMPIAR FILTROS',
          onTap: _limpiar,
        ),
      for (final cancha in views) ...[
        SpaceCard(
          space: cancha,
          catalog: catalogo,
          onBook: () => _aLosHorarios(consulta, cancha),
        ),
        const SizedBox(height: Spacing.s16),
      ],
    ];
  }

  void _aLosHorarios(_Consulta consulta, Space cancha) {
    final fin = consulta.hasta == 0 ? 24 : consulta.hasta;
    final ruta = Uri(
      path: '/sedes/${consulta.venue.id}/canchas/${cancha.id}',
      queryParameters: {
        'fecha': isoDate(consulta.fecha),
        'horas': '${fin - consulta.desde}',
        'inicio': hhmm(consulta.desde),
      },
    );
    // Encima de la búsqueda: al volver, los filtros y el resultado siguen ahí.
    context.push(ruta.toString());
  }
}
