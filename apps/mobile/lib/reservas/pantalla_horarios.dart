import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../comun/formato_precio.dart';
import '../comun/linea_del_dia.dart';
import '../comun/movimiento.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sedes/fotos.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'eleccion.dart';
import '../comun/fechas.dart';
import 'horarios.dart';
import 'pantalla_confirmar_cambio.dart';
import 'pantalla_confirmar_reserva.dart';
import 'marco_elegible.dart';
import 'reglas_busqueda.dart';
import 'reservas.dart';

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

  final int sedeId;
  final int espacioId;
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
  late int _elegida = widget.espacioId;
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
  (int, int)? _deLaGrilla;

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
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
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
    } on SinConexion catch (e) {
      fallo = e;
    } on ErrorDelServidor catch (e) {
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

  void _elegirCancha(int id) {
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
          : _BarraAccion(
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
                  _Portada(
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
                          _Nota(
                            texto:
                                'Estás modificando tu reserva del '
                                '${diaCorto(modificando.inicio)}, '
                                '${rangoDeHoras(modificando.inicio, modificando.fin)}. '
                                'Mantenés la misma duración de ${duracion(_horas)} '
                                'y el horario anterior se libera al guardar.',
                          ),
                          const SizedBox(height: Medidas.s24),
                        ],
                        _Seccion(
                          titulo: 'SELECCIONÁ CANCHA',
                          child: _DeAPares(
                            hijos: [
                              for (final c in datos.$2)
                                _TarjetaCancha(
                                  cancha: c,
                                  elegida: c.id == _elegida,
                                  alTocar: () => _elegirCancha(c.id),
                                ),
                            ],
                          ),
                        ),
                        if (_hoy case final hoy?) ...[
                          _Seccion(
                            titulo: 'FECHA',
                            child: _Fechas(
                              hoy: hoy,
                              elegida: _fecha,
                              alElegir: _elegirFecha,
                            ),
                          ),
                          if (modificando == null)
                            _Seccion(
                              titulo: 'DURACIÓN',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Duracion(
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
                          _Resumen(
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
    return _Seccion(
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
                  _DeAPares(
                    alto: Medidas.altoControl,
                    hijos: [
                      for (final f in grilla.franjas)
                        _TarjetaFranja(
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
                    _Nota(
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

/// La foto del deporte con el camino de vuelta, el tipo y la sede.
class _Portada extends StatelessWidget {
  const _Portada({
    required this.sede,
    required this.tipo,
    required this.deporte,
    required this.volverA,
    required this.alVolver,
  });

  final Sede sede;
  final String tipo;
  final String deporte;

  /// El nombre de la pantalla a la que se vuelve.
  final String volverA;
  final VoidCallback alVolver;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return FotoConVelo(
      imagen: fotoDeDeporte(deporte),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s12,
            Medidas.s8,
            Medidas.s24,
            Medidas.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: alVolver,
                style: TextButton.styleFrom(
                  foregroundColor: p.textOnMedia,
                  minimumSize: const Size(0, Medidas.tactil),
                  textStyle: Textos.leyenda,
                ),
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                label: Text(volverA),
              ),
              const SizedBox(height: Medidas.s32),
              Padding(
                padding: const EdgeInsets.only(left: Medidas.s12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tipo,
                      style: Textos.sobretitulo.copyWith(
                        color: p.accentOnMedia,
                      ),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Semantics(
                      header: true,
                      child: Text(
                        sede.nombre.toUpperCase(),
                        style: Textos.display.copyWith(color: p.textOnMedia),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Padding(
      padding: const EdgeInsets.only(bottom: Medidas.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              titulo,
              style: Textos.sobretitulo.copyWith(color: p.textMuted),
            ),
          ),
          const SizedBox(height: Medidas.s8),
          child,
        ],
      ),
    );
  }
}

/// Dos columnas iguales, como las grillas del prototipo.
class _DeAPares extends StatelessWidget {
  const _DeAPares({required this.hijos, this.alto});

  final List<Widget> hijos;
  final double? alto;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < hijos.length; i += 2) ...[
          if (i > 0) const SizedBox(height: Medidas.s8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _alto(hijos[i])),
                const SizedBox(width: Medidas.s8),
                Expanded(
                  child: i + 1 < hijos.length
                      ? _alto(hijos[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _alto(Widget hijo) {
    final a = alto;
    return a == null
        ? hijo
        : ConstrainedBox(
            constraints: BoxConstraints(minHeight: a),
            child: hijo,
          );
  }
}

class _TarjetaCancha extends StatelessWidget {
  const _TarjetaCancha({
    required this.cancha,
    required this.elegida,
    required this.alTocar,
  });

  final Espacio cancha;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return MarcoElegible(
      etiqueta: 'Cancha ${cancha.numero}, ${cancha.condicion}',
      elegido: elegida,
      alTocar: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(Medidas.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancha ${cancha.numero}',
              style: Textos.cuerpoFuerte.copyWith(
                color: elegida ? p.accentOn : p.textPrimary,
              ),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              cancha.condicion,
              style: Textos.leyenda.copyWith(
                color: elegida ? p.accentOn : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Los próximos siete días desde hoy, en una fila que se desliza.
class _Fechas extends StatelessWidget {
  const _Fechas({
    required this.hoy,
    required this.elegida,
    required this.alElegir,
  });

  final DateTime hoy;
  final DateTime? elegida;
  final ValueChanged<DateTime> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < diasALaVista; i++) ...[
            if (i > 0) const SizedBox(width: Medidas.s8),
            Builder(
              builder: (context) {
                final dia = DateTime.utc(hoy.year, hoy.month, hoy.day + i);
                final esta = dia == elegida;
                final tinta = esta ? p.accentOn : p.textPrimary;
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 64,
                  ),
                  child: MarcoElegible(
                    etiqueta: '${diaDeLaSemana(dia)} ${dia.day}',
                    elegido: esta,
                    alTocar: () => alElegir(dia),
                    child: Padding(
                      padding: const EdgeInsets.all(Medidas.s8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            diaAbreviado(dia),
                            style: Textos.sobretitulo.copyWith(
                              color: esta ? p.accentOn : p.textMuted,
                            ),
                          ),
                          Text(
                            '${dia.day}',
                            style: Textos.h2.copyWith(color: tinta),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// `Stepper-Duracion`: una hora menos, la duración y una hora más.
class _Duracion extends StatelessWidget {
  const _Duracion({required this.horas, required this.alCambiar});

  final int horas;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      height: Medidas.altoControl,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Row(
        children: [
          _BotonRedondo(
            icono: Icons.remove_rounded,
            etiqueta: 'Una hora menos',
            alTocar: horas > minHoras ? () => alCambiar(horas - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                duracion(horas),
                textAlign: TextAlign.center,
                style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          _BotonRedondo(
            icono: Icons.add_rounded,
            etiqueta: 'Una hora más',
            alTocar: horas < maxHoras ? () => alCambiar(horas + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final activo = alTocar != null;
    return Semantics(
      container: true,
      button: true,
      enabled: activo,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: SizedBox(
        width: Medidas.s48,
        height: Medidas.s48,
        child: Material(
          color: activo ? p.bgSurface : Colors.transparent,
          shape: CircleBorder(
            side: BorderSide(
              color: activo ? p.borderControl : Colors.transparent,
            ),
          ),
          child: InkWell(
            onTap: alTocar,
            customBorder: const CircleBorder(),
            child: Icon(
              icono,
              size: 22,
              color: activo ? p.textPrimary : p.stateDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaFranja extends StatelessWidget {
  const _TarjetaFranja({
    required this.franja,
    required this.elegida,
    required this.alTocar,
    this.actual = false,
  });

  final Franja franja;
  final bool elegida;
  final VoidCallback? alTocar;

  /// Es el horario de la reserva que se modifica.
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tinta = elegida ? p.accentOn : p.textPrimary;
    return _Crece(
      activo: elegida,
      child: MarcoElegible(
        etiqueta: actual ? '${franja.texto} (actual)' : franja.texto,
        elegido: elegida,
        alTocar: alTocar,
        atenuado: !franja.disponible,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                franja.texto,
                style: Textos.cuerpoFuerte.copyWith(color: tinta),
              ),
              if (actual)
                Text(
                  '(actual)',
                  style: Textos.leyenda.copyWith(
                    color: elegida ? p.accentOn : p.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Crece de 0,88 a 1 con rebote cada vez que [activo] pasa de falso a verdadero.
class _Crece extends StatefulWidget {
  const _Crece({required this.activo, required this.child});

  final bool activo;
  final Widget child;

  @override
  State<_Crece> createState() => _CreceState();
}

class _CreceState extends State<_Crece> with SingleTickerProviderStateMixin {
  late final _controlador = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late final Animation<double> _escala = _controlador.drive(
    Tween<double>(
      begin: 0.88,
      end: 1,
    ).chain(CurveTween(curve: Movimiento.rebote)),
  );

  @override
  void didUpdateWidget(_Crece anterior) {
    super.didUpdateWidget(anterior);
    if (!widget.activo || anterior.activo) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    unawaited(_controlador.forward(from: 0));
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _escala, child: widget.child);
}

/// `Nota-Ocupados`: cuántos inicios de la grilla no se pueden elegir.
class _Nota extends StatelessWidget {
  const _Nota({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.all(Medidas.s12),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
        border: Border.all(color: p.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: p.textSecondary),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Text(
              texto,
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// La tarjeta de resumen: el precio, y el total con el horario y la fecha elegidos.
class _Resumen extends StatelessWidget {
  const _Resumen({
    required this.tipo,
    required this.precio,
    required this.horas,
    required this.franja,
    required this.fecha,
  });

  final String tipo;
  final int precio;
  final int horas;
  final Franja? franja;
  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final elegida = franja;
    final dia = fecha;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.bgSurfaceRaised,
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          border: Border.all(color: p.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Con el texto grande, cada dato baja a su propia línea en vez de cortarse.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Medidas.s8,
              runSpacing: Medidas.s4,
              children: [
                Text(
                  tipo,
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
                Text(
                  elegida == null
                      ? '${pesos(precio)} por hora'
                      : '${pesos(precio)} × $horas',
                  style: Textos.cuerpo.copyWith(color: p.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: Medidas.s12),
            Divider(height: 1, color: p.borderDefault),
            const SizedBox(height: Medidas.s12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: Medidas.s8,
              runSpacing: Medidas.s8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL',
                      style: Textos.sobretitulo.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: Medidas.s4),
                    Text(
                      elegida == null ? '—' : pesos(precio * horas),
                      style: Textos.h1.copyWith(color: p.accentInk),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      elegida?.texto ?? 'Sin horario elegido',
                      style: Textos.cuerpoFuerte.copyWith(
                        color: elegida == null
                            ? p.textSecondary
                            : p.textPrimary,
                      ),
                    ),
                    if (dia != null)
                      Text(
                        fechaLarga(dia),
                        style: Textos.leyenda.copyWith(color: p.textMuted),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraAccion extends StatelessWidget {
  const _BarraAccion({required this.texto, required this.alContinuar});

  final String texto;
  final VoidCallback? alContinuar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.bgSurface,
        border: Border(top: BorderSide(color: p.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s16,
            Medidas.s24,
            Medidas.s16,
          ),
          child: BotonPrimario(texto: texto, alTocar: alContinuar),
        ),
      ),
    );
  }
}

/// El día de [momento], en la hora del club.
DateTime _diaDe(DateTime momento) =>
    DateTime.utc(momento.year, momento.month, momento.day);
