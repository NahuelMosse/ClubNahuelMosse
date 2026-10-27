import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/carga_de_lista.dart';
import '../comun/estado_vacio.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'barra_de_pestanas_reservas.dart';
import 'cancelacion.dart';
import 'confirmar_cancelacion.dart';
import 'reservas.dart';
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
  final String? reservaId;

  /// Abre en el historial: para los avisos de una reserva que ya no está entre las próximas.
  final bool enHistorial;

  @override
  State<PantallaMisReservas> createState() => _PantallaMisReservasState();
}

class _PantallaMisReservasState extends State<PantallaMisReservas> {
  late bool _historial = widget.enHistorial;
  (List<Reserva>, Catalogo)? _datos;
  bool _fallo = false;

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
      final lista = await widget.reservas.mias(historial: _historial);
      if (mounted && pedido == _pedido) {
        setState(() => _datos = (lista, catalogo));
        _traerALaVista();
      }
      return;
    } on SesionVencida {
      vencida = true;
    } on FalloDeRed catch (e) {
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
  String? _cancelando;

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
      final lista = await widget.reservas.mias(historial: _historial);
      final catalogo = await widget.espacios.catalogo();
      if (mounted && pedido == _pedido) {
        setState(() => _datos = (lista, catalogo));
      }
    } on Exception {
      // Sin red o con el servidor caído, la lista vieja sigue siendo lo mejor que hay.
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Medidas.paginaDeLista,
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
                  CambioDeLista(
                    child: Column(
                      key: ValueKey((datos == null, _fallo, _historial)),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (datos == null && !_fallo) const EsperaDeLista(),
                        if (datos == null && _fallo)
                          ReintentoDeLista(alTocar: _cargar),
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
                      ],
                    ),
                  ),
                ],
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
