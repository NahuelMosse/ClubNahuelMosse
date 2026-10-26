import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/estado_vacio.dart';
import '../sesion/fallo_de_carga.dart';
import '../comun/formato_precio.dart';
import '../comun/movimiento.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'cancelacion.dart';
import '../comun/fechas.dart';
import 'reservas.dart';
import 'barra_de_pestanas_reservas.dart';
import 'tarjeta_reserva.dart';

export 'tarjeta_reserva.dart' show TarjetaReserva;

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
      await avisarSesionVencida(context, widget.sesion);
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
                    BarraDePestanasReservas(
                      historial: _historial,
                      alElegir: _elegir,
                    ),
                    const SizedBox(height: Medidas.s16),
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : Movimiento.cambioDeLista,
                      layoutBuilder: (actual, anteriores) => Stack(
                        alignment: Alignment.topCenter,
                        children: [...anteriores, ?actual],
                      ),
                      child: Column(
                        key: ValueKey((datos == null, _fallo, _historial)),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                key: r.id == widget.reservaId
                                    ? _resaltada
                                    : null,
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
    '${diaCorto(r.inicio)}, ${horarioDe(r)} · '
    '${pesos(r.total)}. El horario vuelve a quedar libre.';
