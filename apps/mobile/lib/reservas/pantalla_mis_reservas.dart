import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../sesion/fallo_de_carga.dart';
import '../comun/formato_precio.dart';
import '../comun/insignia.dart';
import '../comun/reloj.dart';
import '../comun/tarjeta_reserva.dart';
import '../comun/troquel.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../sedes/fotos.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'cancelacion.dart';
import 'fechas.dart';
import 'reservas.dart';

/// «Mis reservas»: las próximas y el historial de quien inició sesión.
class PantallaMisReservas extends StatefulWidget {
  const PantallaMisReservas({
    super.key,
    required this.reservas,
    required this.espacios,
    required this.sesion,
    this.reservaId,
    this.enHistorial = false,
  });

  final Reservas reservas;
  final Espacios espacios;
  final Sesion sesion;

  /// La reserva que se resalta y se trae a la vista, si se llegó desde un aviso.
  final int? reservaId;

  /// Abre en el historial: para los avisos de una reserva que ya no está entre las próximas.
  final bool enHistorial;

  @override
  State<PantallaMisReservas> createState() => _PantallaMisReservasState();
}

class _PantallaMisReservasState extends State<PantallaMisReservas> {
  late bool _historial = widget.enHistorial;
  (List<Reserva>, Catalogo)? _datos;
  bool _fallo = false;

  /// Lo que se manda para pedir la tanda que sigue a la que se ve; `null` si no hay más.
  String? _siguiente;
  bool _cargandoMas = false;
  bool _masFallo = false;

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
  void didUpdateWidget(PantallaMisReservas anterior) {
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
      final tarjeta = _resaltada.currentContext;
      if (mounted && tarjeta != null) {
        Scrollable.ensureVisible(tarjeta, alignment: 0.1);
      }
    });
  }

  /// Con [deCero] (otra pestaña) la lista se vacía mientras llega la nueva; al refrescar
  /// queda la que había hasta que llega la nueva, y se quita si la lectura falla.
  Future<void> _cargar({bool deCero = true}) async {
    final pedido = ++_pedido;
    setState(() {
      if (deCero) _datos = null;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    try {
      final catalogo = await widget.espacios.catalogo();
      final tanda = await widget.reservas.tanda(historial: _historial);
      if (mounted && pedido == _pedido) {
        setState(() => _mostrar(tanda, catalogo));
        _traerALaVista();
      }
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
      _datos = null;
      _fallo = true;
    });
    await avisarFalloDeCarga(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: fallo,
      reintentar: _cargar,
    );
  }

  /// La reserva que se está cancelando: su botón muestra que espera y los demás quedan
  /// deshabilitados.
  int? _cancelando;

  /// Pide confirmación y cancela [r]. Al terminar, bien o porque la reserva ya había
  /// cambiado, la lista se vuelve a leer.
  Future<void> _cancelar(Reserva r, Catalogo catalogo) async {
    if (_cancelando != null) return;
    final confirmo = await confirmarCancelacion(
      context,
      textoDeCancelacion(r, catalogo),
    );
    if (!confirmo || !mounted) return;
    await cancelarConAvisos(
      context,
      sesion: widget.sesion,
      reservas: widget.reservas,
      reserva: r,
      toleraCorte: true,
      marcar: (id) => setState(() => _cancelando = id),
      // Sale de Próximas ya, así no se puede tocar de nuevo mientras llega la lista.
      alCancelar: () => setState(() {
        if (_datos case (final lista, final catalogo)) {
          _datos = ([...lista.where((x) => x.id != r.id)], catalogo);
        }
        _cancelando = null;
      }),
      recargar: () => _cargar(deCero: false),
      releer: _releerSinAvisar,
    );
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee la lista de nuevo.
  Future<void> _modificar(Reserva r) async {
    if (await abrirModificar(context, r)) await _releerSinAvisar();
  }

  /// Vuelve a leer la lista sin avisos: si no se puede, queda la que había.
  Future<void> _releerSinAvisar() async {
    final pedido = ++_pedido;
    try {
      final tanda = await widget.reservas.tanda(historial: _historial);
      final catalogo = await widget.espacios.catalogo();
      if (mounted && pedido == _pedido) {
        setState(() => _mostrar(tanda, catalogo));
      }
    } on Exception {
      // Sin red o con el servidor caído, la lista vieja sigue siendo lo mejor que hay.
    }
  }

  /// Deja a la vista la primera tanda leída.
  void _mostrar(TandaDeReservas tanda, Catalogo catalogo) {
    _datos = (tanda.reservas, catalogo);
    _siguiente = tanda.siguiente;
    _cargandoMas = false;
    _masFallo = false;
  }

  /// Al llegar al final del historial trae la tanda que sigue y la suma a las que ya están,
  /// sin repetir ninguna.
  Future<void> _cargarMas() async {
    final despues = _siguiente;
    if (despues == null || _cargandoMas || _masFallo || _datos == null) return;
    final pedido = _pedido;
    setState(() => _cargandoMas = true);
    var vencida = false;
    var fallo = false;
    try {
      final tanda = await widget.reservas.tanda(
        historial: _historial,
        despues: despues,
      );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        if (_datos case (final lista, final catalogo)) {
          final vistas = {for (final r in lista) r.id};
          _datos = (
            [...lista, ...tanda.reservas.where((r) => vistas.add(r.id))],
            catalogo,
          );
        }
        _siguiente = tanda.siguiente;
        _cargandoMas = false;
      });
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion {
      fallo = true;
    } on ErrorDelServidor {
      fallo = true;
    }
    if (!mounted || pedido != _pedido) return;
    setState(() {
      _cargandoMas = false;
      _masFallo = fallo;
    });
    if (vencida && ModalRoute.of(context)?.isCurrent != false) {
      await mostrarSesionVencida(context);
      if (mounted) await cerrarSesion(context, widget.sesion);
    }
  }

  void _elegir(bool historial) {
    if (historial == _historial) return;
    setState(() => _historial = historial);
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    return PopScope(
      canPop: _cancelando == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelando != null,
          child: const BarraInferior(actual: Seccion.reservas),
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () => _cargar(deCero: false),
            // Las tandas son de 20: se construyen todas las que ya llegaron, así el lector
            // de pantalla llega a cada una sin tener que deslizar primero.
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.depth == 0 && n.metrics.extentAfter < 300) {
                  _cargarMas();
                }
                return false;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s24,
                  Medidas.s24,
                  Medidas.s24,
                  Medidas.s40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Mis reservas',
                              style: Textos.h1.copyWith(color: p.textPrimary),
                            ),
                          ),
                        ),
                        BotonCuenta(sesion: widget.sesion),
                      ],
                    ),
                    const SizedBox(height: Medidas.s16),
                    _Pestanas(historial: _historial, alElegir: _elegir),
                    const SizedBox(height: Medidas.s16),
                    if (datos == null && !_fallo)
                      const Padding(
                        padding: EdgeInsets.all(Medidas.s40),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (datos == null && _fallo)
                      Padding(
                        padding: const EdgeInsets.all(Medidas.s24),
                        child: Center(
                          child: BotonTexto(
                            texto: 'REINTENTAR',
                            alTocar: _cargar,
                          ),
                        ),
                      ),
                    if (datos != null && datos.$1.isEmpty)
                      EstadoVacio(
                        titulo: _historial
                            ? 'No hay reservas pasadas'
                            : 'No hay próximas reservas',
                        texto: _historial
                            ? 'No se encontraron reservas pasadas asociadas a tu cuenta.'
                            : 'No se encontraron próximas reservas asociadas a tu cuenta.',
                      ),
                    if (datos != null)
                      for (final r in datos.$1) ...[
                        TarjetaReserva(
                          reserva: r,
                          catalogo: datos.$2,
                          key: r.id == widget.reservaId ? _resaltada : null,
                          resaltada: r.id == widget.reservaId,
                          cancelable: !_historial && r.cancelable,
                          cancelando: _cancelando == r.id,
                          alCancelar: _cancelando == null
                              ? () => _cancelar(r, datos.$2)
                              : null,
                          alModificar: _cancelando == null
                              ? () => _modificar(r)
                              : null,
                        ),
                        const SizedBox(height: Medidas.s12),
                      ],
                    if (_cargandoMas)
                      const Padding(
                        padding: EdgeInsets.all(Medidas.s16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_masFallo)
                      Center(
                        child: BotonTexto(
                          texto: 'REINTENTAR',
                          alTocar: () {
                            setState(() => _masFallo = false);
                            _cargarMas();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que se le pide confirmar a quien va a cancelar [r].
String textoDeCancelacion(Reserva r, Catalogo catalogo) =>
    '${catalogo.tipoCorto(r.deporte, r.tipo)} · ${r.sede} · '
    '${fechaLarga(r.inicio).split(' de ').first}, ${_horarioDe(r)} · '
    '${pesos(r.total)}. El horario vuelve a quedar libre.';

/// «21:00 – 22:00».
String _horarioDe(Reserva r) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(r.inicio.hour)}:${dos(r.inicio.minute)} – '
      '${dos(r.fin.hour)}:${dos(r.fin.minute)}';
}

/// `Segmented-Tab`: Próximas o Historial.
class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.historial, required this.alElegir});

  final bool historial;
  final ValueChanged<bool> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    Widget pestana(String texto, bool esHistorial) {
      final elegida = historial == esHistorial;
      return Expanded(
        child: Semantics(
          container: true,
          button: true,
          selected: elegida,
          label: texto,
          excludeSemantics: true,
          onTap: () => alElegir(esHistorial),
          child: Material(
            color: elegida ? p.accentBase : Colors.transparent,
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: () => alElegir(esHistorial),
              customBorder: const StadiumBorder(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: Medidas.s48),
                child: Center(
                  child: Text(
                    texto,
                    style: Textos.cuerpoFuerte.copyWith(
                      color: elegida ? p.accentOn : p.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Medidas.s4),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Row(
        children: [
          pestana('Próximas', false),
          const SizedBox(width: Medidas.s4),
          pestana('Historial', true),
        ],
      ),
    );
  }
}

/// `Card-Reserva`: deporte, sede y dirección, precio y estado arriba; el espacio, la fecha
/// y el horario abajo, con el porqué si se canceló o se anuló.
class TarjetaReserva extends StatelessWidget {
  const TarjetaReserva({
    super.key,
    required this.reserva,
    required this.catalogo,
    this.resaltada = false,
    this.cancelable = false,
    this.cancelando = false,
    this.cuentaRegresiva = false,
    this.alCancelar,
    this.alModificar,
  });

  final Reserva reserva;
  final Catalogo catalogo;

  /// Suma «HOY», «MAÑANA» o «FALTAN N DÍAS» a una reserva activa.
  final bool cuentaRegresiva;

  /// Viene de un aviso: se marca con el borde de acento.
  final bool resaltada;

  /// Muestra CANCELAR: una próxima que todavía no empezó.
  final bool cancelable;

  /// La cancelación de esta reserva está en camino.
  final bool cancelando;

  /// `null` deshabilita CANCELAR (hay otra cancelación en camino).
  final VoidCallback? alCancelar;

  /// `null` deshabilita MODIFICAR.
  final VoidCallback? alModificar;

  String get _horario => _horarioDe(reserva);

  String? get _porque => switch (reserva.estado) {
    EstadoDeReserva.cancelada => switch (reserva.motivo) {
      final m? when m.trim().isNotEmpty =>
        'Cancelada por vos · el horario quedó liberado · $m',
      _ => 'Cancelada por vos · el horario quedó liberado',
    },
    EstadoDeReserva.anulada => switch (reserva.motivo) {
      final m? when m.trim().isNotEmpty => 'Anulada por el administrador · $m',
      _ => 'Anulada por el administrador',
    },
    _ => null,
  };

  /// Los días de calendario del club que faltan para el inicio, sin mirar la hora.
  String? get _cuenta {
    if (!cuentaRegresiva || reserva.estado != EstadoDeReserva.activa) {
      return null;
    }
    final hoy = ahoraEnElClub();
    final i = reserva.inicio;
    final dias = DateTime(
      i.year,
      i.month,
      i.day,
    ).difference(DateTime(hoy.year, hoy.month, hoy.day)).inDays;
    return switch (dias) {
      <= 0 => 'HOY',
      1 => 'MAÑANA',
      _ => 'FALTAN $dias DÍAS',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final porque = _porque;
    final cuenta = _cuenta;
    final activa = r.estado == EstadoDeReserva.activa;
    final anulada = r.estado == EstadoDeReserva.anulada;
    final grande = MediaQuery.textScalerOf(context).scale(10) > 13;
    final precioYEstado = Column(
      crossAxisAlignment: grande
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          pesos(r.total),
          style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
        ),
        const SizedBox(height: Medidas.s8),
        _Estado(estado: r.estado),
      ],
    );
    final cancelar = alCancelar;
    final modificar = alModificar;
    final deQue =
        '${catalogo.tipoCorto(r.deporte, r.tipo)}, '
        '${fechaLarga(r.inicio).split(' de ').first}, $_horario';
    // La tarjeta se lee entera como un dato; MODIFICAR y CANCELAR quedan afuera, como
    // botones propios.
    final datos = Semantics(
      container: true,
      selected: resaltada,
      excludeSemantics: true,
      label: [
        catalogo.tipoCorto(r.deporte, r.tipo),
        '${r.sede}, ${r.direccion}',
        r.estado.name,
        fechaLarga(r.inicio),
        _horario,
        '${pesos(r.total).replaceFirst('\$\u00A0', '')} pesos',
        r.espacio,
        ?porque,
        ?cuenta?.toLowerCase(),
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Medidas.radioMd),
                  child: Image(
                    image: fotoDeDeporte(r.deporte),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
                const SizedBox(width: Medidas.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            iconoDeDeporte(r.deporte),
                            size: 16,
                            color: p.textSecondary,
                          ),
                          const SizedBox(width: Medidas.s4),
                          Flexible(
                            child: Text(
                              catalogo.tipoCorto(r.deporte, r.tipo),
                              style: Textos.titulo.copyWith(
                                color: p.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Medidas.s4),
                      Text(
                        '${r.sede} · ${r.direccion}',
                        style: Textos.leyenda.copyWith(color: p.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!grande) ...[
                  const SizedBox(width: Medidas.s8),
                  precioYEstado,
                ],
              ],
            ),
          ),
          if (grande)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s16,
                0,
                Medidas.s16,
                Medidas.s16,
              ),
              child: precioYEstado,
            ),
          Troquel(fondo: p.bgBase),
          Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cuenta != null) ...[
                  Text(
                    cuenta,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 11 * 0.08,
                      color: p.accentInk,
                    ),
                  ),
                  const SizedBox(height: Medidas.s4),
                ],
                Text(
                  r.espacio,
                  style: Textos.mono.copyWith(color: p.textMuted),
                ),
                const SizedBox(height: Medidas.s8),
                FechaYHorario(fecha: fechaLarga(r.inicio), horario: _horario),
                if (porque != null) ...[
                  const SizedBox(height: Medidas.s8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: anulada ? p.stateDangerInk : p.textSecondary,
                      ),
                      const SizedBox(width: Medidas.s8),
                      Expanded(
                        child: Text(
                          porque,
                          style: Textos.leyenda.copyWith(
                            color: anulada ? p.stateDangerInk : p.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    final borde = resaltada ? 2.0 : 1.0;
    return Container(
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(
          color: resaltada ? p.borderFocus : p.borderDefault,
          width: borde,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Medidas.radioLg - borde),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                datos,
                if (cancelable)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Medidas.s16,
                      0,
                      Medidas.s16,
                      Medidas.s16,
                    ),
                    child: cancelando
                        ? Semantics(
                            label: 'Cancelando la reserva',
                            excludeSemantics: true,
                            child: const SizedBox(
                              height: Medidas.altoControl,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          )
                        : Flex(
                            direction: grande ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: grande
                                ? CrossAxisAlignment.stretch
                                : CrossAxisAlignment.center,
                            children: [
                              _Accion(
                                expandir: !grande,
                                etiqueta: 'Modificar la reserva de $deQue',
                                alTocar: modificar,
                                child: BotonContorno(
                                  texto: 'MODIFICAR',
                                  alTocar: modificar,
                                  compacto: true,
                                ),
                              ),
                              const SizedBox(
                                width: Medidas.s8,
                                height: Medidas.s8,
                              ),
                              _Accion(
                                expandir: !grande,
                                etiqueta: 'Cancelar la reserva de $deQue',
                                alTocar: cancelar,
                                child: BotonContorno(
                                  texto: 'CANCELAR',
                                  alTocar: cancelar,
                                  peligro: true,
                                  compacto: true,
                                ),
                              ),
                            ],
                          ),
                  ),
              ],
            ),
            if (activa)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(
                  key: const ValueKey('borde-reserva-activa'),
                  color: p.accentBase,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Un botón de la tarjeta, que dice de qué reserva es.
class _Accion extends StatelessWidget {
  const _Accion({
    required this.expandir,
    required this.etiqueta,
    required this.alTocar,
    required this.child,
  });

  final bool expandir;
  final String etiqueta;
  final VoidCallback? alTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final boton = Semantics(
      label: etiqueta,
      excludeSemantics: true,
      button: true,
      enabled: alTocar != null,
      onTap: alTocar,
      child: child,
    );
    return expandir ? Expanded(child: boton) : boton;
  }
}

/// `Badge-Estado`.
class _Estado extends StatelessWidget {
  const _Estado({required this.estado});

  final EstadoDeReserva estado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final (fondo, tinta) = switch (estado) {
      EstadoDeReserva.activa => (p.bgSurface, p.stateSuccessInk),
      EstadoDeReserva.anulada => (p.stateDangerMuted, p.stateDangerInk),
      _ => (p.bgSurface, p.textSecondary),
    };
    return InsigniaDeEstado(
      texto: estado.name.toUpperCase(),
      fondo: fondo,
      tinta: tinta,
    );
  }
}
