import 'package:flutter/material.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/carga_de_lista.dart';
import '../comun/errores_no_manejados.dart';
import '../comun/esqueleto.dart';
import '../comun/fechas.dart';
import '../comun/marcador.dart';
import '../comun/movimiento.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../notificaciones/centro.dart';
import '../reservas/cancelacion.dart';
import '../reservas/confirmar_cancelacion.dart';
import '../reservas/pantalla_mis_reservas.dart';
import '../reservas/reservas.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'accesos_de_inicio.dart';
import 'animacion_de_tiles.dart';
import 'deportes_de_inicio.dart';
import 'hero_de_inicio.dart';
import 'proxima_reserva.dart';

typedef _Datos = ({
  Reserva? proxima,
  int cuantas,
  Catalogo catalogo,
  List<Sede> sedes,
});

/// El Home de quien inicia sesión como usuario: su próxima reserva, cuánto hay para
/// reservar y los atajos a lo que hace todos los días.
class PantallaInicio extends StatefulWidget {
  const PantallaInicio({
    super.key,
    required this.sesion,
    required this.reservas,
    required this.espacios,
    required this.sedes,
    this.centro,
  });

  final Sesion sesion;
  final Reservas reservas;
  final Espacios espacios;
  final Sedes sedes;

  /// Sin él no hay campana: la pantalla no avisa de notificaciones.
  final CentroDeNotificaciones? centro;

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  _Datos? _datos;
  bool _fallo = false;

  /// Sube con cada lectura: la respuesta de una lectura que ya no vale se descarta.
  int _pedido = 0;

  /// La reserva que se está cancelando: su botón muestra que espera.
  String? _cancelando;

  /// Ya se vieron los bloques con datos: los que se vuelven a armar al recargar nacen
  /// terminados, sin repetir la entrada.
  bool _yaEntro = false;

  @override
  void initState() {
    super.initState();
    widget.reservas.addListener(_alCambiarLasReservas);
    _cargar();
  }

  @override
  void didUpdateWidget(PantallaInicio anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.reservas != widget.reservas) {
      anterior.reservas.removeListener(_alCambiarLasReservas);
      widget.reservas.addListener(_alCambiarLasReservas);
    }
    if (anterior.reservas != widget.reservas ||
        anterior.espacios != widget.espacios ||
        anterior.sedes != widget.sedes) {
      _cargar();
    }
  }

  @override
  void dispose() {
    widget.reservas.removeListener(_alCambiarLasReservas);
    super.dispose();
  }

  /// Una reserva cambió desde otra pantalla: la próxima puede ser otra. Las que cambian
  /// desde acá se releen al terminar.
  void _alCambiarLasReservas() {
    if (_cancelando == null) _releerSinAvisar();
  }

  Future<_Datos> _leer() async {
    final catalogo = await widget.espacios.catalogo();
    final proximas = await widget.reservas.mias(historial: false);
    final sedes = await widget.sedes.activas();
    return (
      proxima: proximas.firstOrNull,
      cuantas: proximas.length,
      catalogo: catalogo,
      sedes: sedes,
    );
  }

  /// Con [deCero] la pantalla se vacía mientras llega la lectura; al refrescar queda lo que
  /// había hasta que llega lo nuevo, y se quita si la lectura falla.
  Future<void> _cargar({bool deCero = true}) async {
    final pedido = ++_pedido;
    setState(() {
      if (deCero) _datos = null;
      _fallo = false;
    });
    Object? fallo;
    var vencida = false;
    try {
      final datos = await _leer();
      if (mounted && pedido == _pedido) setState(() => _datos = datos);
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

  /// Vuelve a leer sin avisos: si no se puede, queda lo que había.
  Future<void> _releerSinAvisar() async {
    final pedido = ++_pedido;
    try {
      final datos = await _leer();
      if (mounted && pedido == _pedido) setState(() => _datos = datos);
    } on Exception catch (e, pila) {
      // Sin red o con el servidor caído, lo que había sigue siendo lo mejor que hay.
      registrarError(e, pila);
    }
  }

  /// Pide confirmación y cancela [r]. Al terminar, bien o porque la reserva ya había
  /// cambiado, el Home se vuelve a leer.
  Future<void> _cancelar(Reserva r, Catalogo catalogo) async {
    if (_cancelando != null) return;
    final confirmo = await confirmarCancelacion(
      context,
      textoDeCancelacion(r, catalogo),
    );
    if (!confirmo || !mounted) return;
    // Una lectura que venía en camino (deslizar para refrescar) ya no vale.
    _pedido++;
    await cancelarConAvisos(
      context,
      sesion: widget.sesion,
      reservas: widget.reservas,
      reserva: r,
      marcar: (id) => setState(() => _cancelando = id),
      alCancelar: () => setState(() {
        if (_datos case final datos?) {
          _datos = (
            proxima: null,
            cuantas: datos.cuantas > 0 ? datos.cuantas - 1 : 0,
            catalogo: datos.catalogo,
            sedes: datos.sedes,
          );
        }
        _cancelando = null;
      }),
      recargar: () => _cargar(deCero: false),
      releer: _releerSinAvisar,
    );
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee el Home de nuevo.
  Future<void> _modificar(Reserva r) async {
    if (await abrirModificar(context, r, ruta: '?desde=inicio')) {
      await _releerSinAvisar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    final proxima = datos?.proxima;
    final yaEntro = _yaEntro;
    if (datos != null) _yaEntro = true;
    return PopScope(
      canPop: _cancelando == null,
      child: Scaffold(
        backgroundColor: p.bgBase,
        bottomNavigationBar: IgnorePointer(
          ignoring: _cancelando != null,
          child: const BarraInferior(actual: Seccion.inicio),
        ),
        body: AbsorbPointer(
          absorbing: _cancelando != null,
          child: RefreshIndicator(
            onRefresh: () => _cargar(deCero: false),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeroDeInicio(
                    sesion: widget.sesion,
                    centro: widget.centro,
                    celdas: datos == null ? null : _celdas(datos),
                    yaEntro: yaEntro,
                  ),
                  if (datos == null && !_fallo)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Medidas.s24),
                      child: EsqueletoDeLista(forma: FormaDeEsqueleto.reserva),
                    ),
                  if (datos == null && _fallo)
                    ReintentoDeLista(alTocar: _cargar),
                  if (datos != null) ...[
                    if (proxima != null)
                      Aparecer(
                        retraso: const Duration(milliseconds: 450),
                        desdeY: 26,
                        yaEntro: yaEntro,
                        child: ProximaReserva(
                          reserva: proxima,
                          catalogo: datos.catalogo,
                          cancelando: _cancelando == proxima.id,
                          alCancelar: _cancelando == null
                              ? () => _cancelar(proxima, datos.catalogo)
                              : null,
                          alModificar: _cancelando == null
                              ? () => _modificar(proxima)
                              : null,
                        ),
                      ),
                    DeportesDeInicio(
                      catalogo: datos.catalogo,
                      yaEntro: yaEntro,
                    ),
                    AccesosDeInicio(
                      primero:
                          entradaDeTiles +
                          pasoDeTiles * datos.catalogo.deportes.length,
                      yaEntro: yaEntro,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<CeldaMarcador> _celdas(_Datos datos) {
  final canchas = datos.sedes.fold(0, (total, s) => total + s.canchas);
  return [
    CeldaMarcador(cifra: dosCifras(datos.sedes.length), rotulo: 'SEDES'),
    CeldaMarcador(cifra: dosCifras(canchas), rotulo: 'CANCHAS'),
    CeldaMarcador(
      cifra: dosCifras(datos.cuantas),
      rotulo: 'PRÓXIMAS',
      destacada: true,
    ),
  ];
}
