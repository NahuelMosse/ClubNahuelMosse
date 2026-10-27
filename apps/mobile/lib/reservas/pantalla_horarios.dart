import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/fechas.dart';
import '../comun/linea_del_dia.dart';
import '../comun/movimiento.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'barra_de_accion_horarios.dart';
import 'eleccion.dart';
import 'franja_de_fechas.dart';
import 'grilla_de_a_pares.dart';
import 'horarios.dart';
import 'nota_de_horarios.dart';
import 'pantalla_confirmar_cambio.dart';
import 'pantalla_confirmar_reserva.dart';
import 'portada_de_horarios.dart';
import 'reglas_busqueda.dart';
import 'reservas.dart';
import 'resumen_de_reserva.dart';
import 'seccion_de_horarios.dart';
import 'selector_de_duracion.dart';
import 'tarjeta_cancha_de_horarios.dart';
import 'tarjeta_franja.dart';

/// «Horarios disponibles» de una cancha: elige cancha de ese tipo, fecha y duración, y la
/// franja que después se confirma. Consultar no reserva nada.
class PantallaHorarios extends StatefulWidget {
  const PantallaHorarios({
    super.key,
    required this.sedeId,
    required this.espacioId,
    required this.sedes,
    required this.espacios,
    required this.horarios,
    required this.sesion,
    this.fecha,
    this.horas,
    this.inicio,
    this.modificando,
    this.volverA = 'Mis reservas',
  });

  final String sedeId;
  final String espacioId;
  final Sedes sedes;
  final Espacios espacios;
  final Horarios horarios;
  final Sesion sesion;

  /// Lo que ya viene elegido desde la consulta de canchas: el día, la duración y la hora
  /// de inicio (`HH:MM`). La hora queda elegida si está disponible.
  final DateTime? fecha;
  final int? horas;
  final String? inicio;

  /// La reserva que se está modificando: se mantiene su duración, su franja se ve libre y
  /// marcada, y CONTINUAR CON EL CAMBIO lleva a «Confirmá el cambio».
  final Reserva? modificando;

  /// Cómo se llama la pantalla a la que vuelve la modificación.
  final String volverA;

  @override
  State<PantallaHorarios> createState() => _PantallaHorariosState();
}

class _PantallaHorariosState extends State<PantallaHorarios> {
  (Sede, List<Espacio>, Catalogo)? _datos;
  late String _elegida = widget.espacioId;
  late DateTime? _fecha = switch (widget.modificando) {
    final r? => _diaDe(r.inicio),
    null => widget.fecha,
  };
  late int _horas = switch ((widget.modificando, widget.horas)) {
    (final r?, _) => r.fin.difference(r.inicio).inHours,
    (_, final h?) when h >= minHoras && h <= maxHoras => h,
    _ => minHoras,
  };
  Grilla? _grilla;

  /// La cancha y la duración con que se pidió la grilla que está en pantalla: mientras
  /// llega otra, el resumen y la nota siguen hablando de esa.
  (String, int)? _deLaGrilla;

  /// El día de hoy en el club, según la última grilla: FECHA sigue a la vista aunque la
  /// consulta siguiente falle.
  DateTime? _hoy;
  late String? _inicio = switch (widget.modificando) {
    final r? => horaCorta(r.inicio),
    null => widget.inicio,
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

  Espacio? get _cancha => _datos?.$2.where((c) => c.id == _elegida).firstOrNull;

  /// La franja de [inicio] en la cancha y el día elegidos es la de la reserva que se
  /// modifica.
  bool _esLaActual(String inicio) => switch (widget.modificando) {
    final r? =>
      r.espacioId == _elegida &&
          _fecha == _diaDe(r.inicio) &&
          inicio == horaCorta(r.inicio),
    null => false,
  };

  bool get _puedeSeguir {
    final inicio = _inicio;
    return inicio != null && !_consultando && !_esLaActual(inicio);
  }

  Future<void> _cargar() async {
    setState(() => _fallo = false);
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final sedes = await widget.sedes.activas();
      final sede = sedes.where((s) => s.id == widget.sedeId).firstOrNull;
      final canchas = await widget.espacios.activos(sedeId: widget.sedeId);
      final elegida = canchas
          .where((c) => c.id == widget.espacioId)
          .firstOrNull;
      if (!mounted) return;
      if (sede == null || elegida == null) {
        await _yaNoEsta(sede == null);
        return;
      }
      setState(() {
        _datos = (
          sede,
          [
            for (final c in canchas)
              if (c.deporte == elegida.deporte && c.tipo == elegida.tipo) c,
          ],
          catalogo,
        );
      });
      await _consultar();
      return;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    await _avisar(vencida: vencida, fallo: fallo, reintentar: _cargar);
  }

  /// Pide la grilla de la cancha, la fecha y la duración elegidas. La hora de inicio
  /// elegida queda si sigue disponible.
  Future<void> _consultar() async {
    final pedido = ++_pedido;
    setState(() {
      _consultando = true;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    final consulta = (_elegida, _horas);
    try {
      final grilla = await widget.horarios.de(
        _elegida,
        fecha: _fecha,
        horas: _horas,
        reservaId: widget.modificando?.id,
      );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _consultando = false;
        _grilla = grilla;
        _deLaGrilla = consulta;
        _hoy = grilla.hoy;
        _fecha = grilla.fecha;
        final sigue = grilla.franjas.any(
          (f) => f.inicio == _inicio && f.disponible,
        );
        if (!sigue) _inicio = null;
      });
      return;
    } on CanchaNoDisponible {
      if (mounted && pedido == _pedido) await _yaNoEsta(false);
      return;
    } on FechaVencida {
      // El día elegido ya pasó (la pantalla quedó abierta de un día para otro): vuelve a hoy.
      if (!mounted || pedido != _pedido || _fecha == null) return;
      _fecha = null;
      _inicio = null;
      await _consultar();
      return;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
      fallo = e;
    }
    if (!mounted || pedido != _pedido) return;
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
      sesion: widget.sesion,
      vencida: vencida,
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
      await mostrarCambioMientrasTanto(context);
      if (mounted) _salir(ResultadoDeModificar.cambio);
      return;
    }
    await mostrarCambioMientrasTanto(context);
    if (!mounted) return;
    if (laSede) {
      widget.sedes.avisarCambio();
    } else {
      widget.espacios.avisarCambio();
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

  void _cambiarHoras(int horas) {
    setState(() => _horas = horas);
    _consultar();
  }

  Future<void> _continuar() async {
    final datos = _datos;
    final cancha = _cancha;
    final fecha = _fecha;
    final franja = _grilla?.franjas
        .where((f) => f.inicio == _inicio)
        .firstOrNull;
    if (datos == null || cancha == null || fecha == null || franja == null) {
      return;
    }
    final eleccion = Eleccion(
      sede: datos.$1,
      cancha: cancha,
      tipo: datos.$3.tipoCorto(cancha.deporte, cancha.tipo),
      fecha: fecha,
      inicio: franja.inicio,
      fin: franja.fin,
      horas: _horas,
    );
    if (widget.modificando case final reserva?) {
      final resultado = await context.push<ResultadoDeModificar>(
        '/reservas/${reserva.id}/modificar/confirmar',
        extra: (reserva, eleccion),
      );
      if (!mounted) return;
      if (resultado == ResultadoDeModificar.ocupado) {
        setState(() => _inicio = null);
        await _consultar();
      } else if (resultado != null) {
        _salir(resultado);
      }
      return;
    }
    final resultado = await context.push<ResultadoDeConfirmar>(
      '/sedes/${widget.sedeId}/canchas/${widget.espacioId}/reservar',
      extra: eleccion,
    );
    if (resultado == ResultadoDeConfirmar.ocupado && mounted) {
      setState(() => _inicio = null);
      await _consultar();
    }
  }

  /// Vuelve a la pantalla de la que vino con cómo terminó la modificación.
  void _salir([ResultadoDeModificar? resultado]) {
    if (context.canPop()) {
      context.pop(resultado);
    } else {
      context.go('/reservas');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    final cancha = _cancha;
    final modificando = widget.modificando;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: datos == null
          ? null
          : BarraDeAccionHorarios(
              texto: modificando == null
                  ? 'CONTINUAR'
                  : 'CONTINUAR CON EL CAMBIO',
              alContinuar: _puedeSeguir ? _continuar : null,
            ),
      body: datos == null || cancha == null
          ? SafeArea(
              child: Center(
                child: _cambio
                    ? const SizedBox.shrink()
                    : _fallo
                    ? BotonTexto(texto: 'REINTENTAR', alTocar: _cargar)
                    : const CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PortadaDeHorarios(
                    sede: datos.$1,
                    tipo: datos.$3.tipoCorto(cancha.deporte, cancha.tipo),
                    deporte: cancha.deporte,
                    volverA: modificando != null
                        ? widget.volverA
                        : widget.fecha == null
                        ? 'Sedes'
                        : 'Buscar cancha',
                    alVolver: modificando != null
                        ? _salir
                        : () => context.canPop()
                              ? context.pop()
                              : context.go('/sedes/${widget.sedeId}'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Medidas.s24,
                      Medidas.s20,
                      Medidas.s24,
                      Medidas.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (modificando != null) ...[
                          NotaDeHorarios(
                            texto:
                                'Estás modificando tu reserva del '
                                '${diaCorto(modificando.inicio)}, '
                                '${rangoDeHoras(modificando.inicio, modificando.fin)}. '
                                'Mantenés la misma duración de ${duracion(_horas)} '
                                'y el horario anterior se libera al guardar.',
                          ),
                          const SizedBox(height: Medidas.s24),
                        ],
                        SeccionDeHorarios(
                          titulo: 'SELECCIONÁ CANCHA',
                          child: GrillaDeAPares(
                            hijos: [
                              for (final c in datos.$2)
                                TarjetaCanchaDeHorarios(
                                  cancha: c,
                                  elegida: c.id == _elegida,
                                  alTocar: () => _elegirCancha(c.id),
                                ),
                            ],
                          ),
                        ),
                        if (_hoy case final hoy?) ...[
                          SeccionDeHorarios(
                            titulo: 'FECHA',
                            child: FranjaDeFechas(
                              hoy: hoy,
                              elegida: _fecha,
                              alElegir: _elegirFecha,
                            ),
                          ),
                          if (modificando == null)
                            SeccionDeHorarios(
                              titulo: 'DURACIÓN',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SelectorDeDuracion(
                                    horas: _horas,
                                    alCambiar: _cambiarHoras,
                                  ),
                                  const SizedBox(height: Medidas.s8),
                                  Text(
                                    'Horas completas, de $minHoras a $maxHoras h. '
                                    'La sede cierra a las ${datos.$1.cierre}.',
                                    style: Textos.leyenda.copyWith(
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        _grillaOAviso(p),
                        if ((_grilla, _deLaGrilla) case (
                          final grilla?,
                          (final id, final horas)?,
                        )) ...[
                          const SizedBox(height: Medidas.s8),
                          ResumenDeReserva(
                            tipo: datos.$3.tipoCorto(
                              cancha.deporte,
                              cancha.tipo,
                            ),
                            precio:
                                (datos.$2
                                            .where((c) => c.id == id)
                                            .firstOrNull ??
                                        cancha)
                                    .precioPorHora,
                            horas: horas,
                            franja: grilla.franjas
                                .where((f) => f.inicio == _inicio)
                                .firstOrNull,
                            fecha: grilla.fecha,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _grillaOAviso(Paleta p) {
    final grilla = _grilla;
    final horas = _deLaGrilla?.$2 ?? _horas;
    if (grilla == null) {
      return Padding(
        padding: const EdgeInsets.all(Medidas.s24),
        child: Center(
          child: _cambio
              ? const SizedBox.shrink()
              : _consultando || !_fallo
              ? const CircularProgressIndicator()
              : BotonTexto(texto: 'REINTENTAR', alTocar: _consultar),
        ),
      );
    }
    return SeccionDeHorarios(
      titulo: 'HORARIO DISPONIBLE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 2,
            child: _consultando ? const LinearProgressIndicator() : null,
          ),
          const SizedBox(height: Medidas.s8),
          _contenidoDeLaGrilla(grilla, horas),
        ],
      ),
    );
  }

  /// Mientras llega otra grilla, la anterior queda atenuada y no se puede tocar.
  Widget _contenidoDeLaGrilla(Grilla grilla, int horas) {
    return IgnorePointer(
      ignoring: _consultando,
      child: AnimatedOpacity(
        opacity: _consultando ? 0.5 : 1,
        duration: const Duration(milliseconds: 150),
        child: !grilla.hayLibres
            ? EstadoVacio(
                titulo: 'No hay horarios disponibles',
                texto: _porQueNoHay(grilla, horas),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_datos?.$1 case final sede?) ...[
                    Latido(
                      disparador: _horas,
                      child: _lineaDelDia(sede, grilla, horas),
                    ),
                    const SizedBox(height: Medidas.s12),
                  ],
                  GrillaDeAPares(
                    alto: Medidas.altoControl,
                    hijos: [
                      for (final f in grilla.franjas)
                        TarjetaFranja(
                          franja: f,
                          actual: _esLaActual(f.inicio),
                          elegida: f.inicio == _inicio,
                          alTocar: f.disponible
                              ? () => setState(() => _inicio = f.inicio)
                              : null,
                        ),
                    ],
                  ),
                  if (grilla.noDisponibles > 0) ...[
                    const SizedBox(height: Medidas.s12),
                    NotaDeHorarios(
                      texto: horas == 1
                          ? 'Algunos horarios ya están ocupados · '
                                '${grilla.noDisponibles} no disponibles'
                          : 'Con ${duracion(horas)} hay menos inicios posibles · '
                                '${grilla.noDisponibles} no disponibles',
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// Una celda por hora, de la apertura a la última antes del cierre: libre si alguna
  /// franja libre la cubre, elegida si la cubre la franja elegida.
  Widget _lineaDelDia(Sede sede, Grilla grilla, int horas) {
    int hora(String hhmm) => int.parse(hhmm.split(':').first);
    final desde = hora(sede.apertura);
    final cierre = hora(sede.cierre);
    final hasta = cierre == 0 ? 24 : cierre;
    bool cubre(Franja f, int h) {
      final inicio = hora(f.inicio);
      return inicio <= h && h < inicio + horas;
    }

    final elegida = grilla.franjas.where((f) => f.inicio == _inicio);
    return LineaDelDia(
      desde: desde,
      franjas: [
        for (var h = desde; h < hasta; h++)
          if (elegida.any((f) => cubre(f, h)))
            EstadoFranja.elegida
          else if (grilla.franjas.any((f) => f.disponible && cubre(f, h)))
            EstadoFranja.libre
          else
            EstadoFranja.ocupada,
      ],
    );
  }

  String _porQueNoHay(Grilla grilla, int horas) {
    if (!grilla.abre) return 'La sede no abre ese día. Probá con otra fecha.';
    if (horas > 1) {
      return 'Con ${duracion(horas)} seguidas no entra ningún turno antes del '
          'cierre. Probá con una duración menor, otra fecha u otra cancha.';
    }
    return 'Ya no quedan turnos libres ese día. Probá con otra fecha u otra cancha.';
  }
}

/// El día de [momento], en la hora del club.
DateTime _diaDe(DateTime momento) =>
    DateTime.utc(momento.year, momento.month, momento.day);
