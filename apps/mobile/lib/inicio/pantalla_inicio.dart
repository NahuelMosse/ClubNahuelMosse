import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../comun/errores_no_manejados.dart';
import '../comun/marcador.dart';
import '../comun/movimiento.dart';
import '../comun/tile_deporte.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../notificaciones/campana.dart';
import '../notificaciones/centro.dart';
import '../reservas/cancelacion.dart';
import '../reservas/pantalla_mis_reservas.dart';
import '../reservas/reservas.dart';
import '../sedes/fotos.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

typedef _Datos = ({
  Reserva? proxima,
  int cuantas,
  bool hayMas,
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
  int? _cancelando;

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
    final proximas = await widget.reservas.tanda(historial: false);
    final sedes = await widget.sedes.activas();
    return (
      proxima: proximas.reservas.firstOrNull,
      cuantas: proximas.reservas.length,
      hayMas: proximas.siguiente != null,
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
            hayMas: datos.hayMas,
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
                  _Hero(
                    sesion: widget.sesion,
                    centro: widget.centro,
                    celdas: datos == null ? null : _celdas(datos),
                    yaEntro: yaEntro,
                  ),
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
                  if (datos != null) ...[
                    if (proxima != null)
                      Aparecer(
                        retraso: const Duration(milliseconds: 450),
                        desdeY: 26,
                        yaEntro: yaEntro,
                        child: _Proxima(
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
                    _Deportes(catalogo: datos.catalogo, yaEntro: yaEntro),
                    _Accesos(
                      primero:
                          _entradaDeTiles +
                          _pasoDeTiles * datos.catalogo.deportes.length,
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

/// Cuándo entra el primer tile de deporte y cuánto después entra cada uno de los que siguen.
const _entradaDeTiles = Duration(milliseconds: 700);
const _pasoDeTiles = Duration(milliseconds: 90);

List<CeldaMarcador> _celdas(_Datos datos) {
  final canchas = datos.sedes.fold(0, (total, s) => total + s.canchas);
  String dos(int n) => '$n'.padLeft(2, '0');
  return [
    CeldaMarcador(cifra: dos(datos.sedes.length), rotulo: 'SEDES'),
    CeldaMarcador(cifra: dos(canchas), rotulo: 'CANCHAS'),
    CeldaMarcador(
      cifra: datos.hayMas ? '20+' : dos(datos.cuantas),
      rotulo: 'PRÓXIMAS',
      destacada: true,
    ),
  ];
}

/// El emoji de un deporte del catálogo; uno que la app no conoce lleva 🏅.
String _emojiDeDeporte(String clave) => switch (clave) {
  'Futbol' => '⚽',
  'Tenis' => '🎾',
  'Padel' => '🏓',
  'Voley' => '🏐',
  'Hockey' => '🏑',
  'Basquet' => '🏀',
  'Golf' => '⛳',
  _ => '🏅',
};

/// La portada: el saludo, la cuenta y el pedido del día. Va sobre una foto, así que sus
/// colores son los `on-media`, iguales en los dos modos.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.sesion,
    required this.celdas,
    required this.yaEntro,
    this.centro,
  });

  final Sesion sesion;
  final bool yaEntro;

  final CentroDeNotificaciones? centro;

  /// `null` mientras se lee.
  final List<CeldaMarcador>? celdas;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final arriba = MediaQuery.paddingOf(context).top;
    final marcador = celdas;
    return FotoConVelo(
      imagen: fotoDeDeporte('Futbol'),
      child: Stack(
        children: [
          const Positioned.fill(
            child: ExcludeSemantics(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.5],
                    colors: [Color(0x99000000), Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              Medidas.s24,
              arriba + Medidas.s24,
              Medidas.s16,
              Medidas.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Aparecer(
                        retraso: const Duration(milliseconds: 50),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BUENOS DÍAS,',
                              style: Textos.sobretitulo.copyWith(
                                color: p.accentOnMedia,
                              ),
                            ),
                            const SizedBox(height: Medidas.s4),
                            ListenableBuilder(
                              listenable: sesion,
                              builder: (context, _) => Text(
                                sesion.perfil?.nombre ?? '',
                                style: Textos.h1.copyWith(color: p.textOnMedia),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (centro case final centro?)
                      BotonNotificaciones(centro: centro),
                    BotonCuenta(sesion: sesion),
                  ],
                ),
                const SizedBox(height: Medidas.s48),
                Semantics(
                  header: true,
                  child: Text(
                    'RESERVÁ TU CANCHA',
                    style: Textos.display.copyWith(color: p.textOnMedia),
                  ),
                ),
                if (marcador != null) ...[
                  const SizedBox(height: Medidas.s24),
                  Padding(
                    padding: const EdgeInsets.only(right: Medidas.s8),
                    child: Aparecer(
                      retraso: const Duration(milliseconds: 250),
                      duracion: const Duration(milliseconds: 500),
                      desdeY: 0,
                      escalaDesde: 0.85,
                      curva: Movimiento.rapida,
                      yaEntro: yaEntro,
                      child: Marcador(celdas: marcador),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// El título de una zona de la pantalla.
class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      texto,
      style: Textos.sobretitulo.copyWith(color: context.paleta.textMuted),
    ),
  );
}

/// «Tu próxima reserva»: la tarjeta de Mis reservas, con sus dos acciones.
class _Proxima extends StatelessWidget {
  const _Proxima({
    required this.reserva,
    required this.catalogo,
    required this.cancelando,
    required this.alCancelar,
    required this.alModificar,
  });

  final Reserva reserva;
  final Catalogo catalogo;
  final bool cancelando;
  final VoidCallback? alCancelar;
  final VoidCallback? alModificar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Medidas.s24,
      Medidas.s24,
      Medidas.s24,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: _Titulo('TU PRÓXIMA RESERVA')),
            BotonTexto(
              texto: 'VER TODAS →',
              alTocar: () => context.go('/reservas'),
            ),
          ],
        ),
        const SizedBox(height: Medidas.s12),
        TarjetaReserva(
          reserva: reserva,
          catalogo: catalogo,
          cancelable: reserva.cancelable,
          cancelando: cancelando,
          cuentaRegresiva: true,
          alCancelar: alCancelar,
          alModificar: alModificar,
        ),
      ],
    ),
  );
}

/// Los deportes del club. Informan; no llevan a ningún lado.
class _Deportes extends StatelessWidget {
  const _Deportes({required this.catalogo, required this.yaEntro});

  final Catalogo catalogo;
  final bool yaEntro;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Medidas.s32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Medidas.s24),
            child: _Titulo('DEPORTES'),
          ),
          const SizedBox(height: Medidas.s12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
            child: Row(
              children: [
                for (final (i, d) in catalogo.deportes.indexed) ...[
                  if (i > 0) const SizedBox(width: Medidas.s12),
                  Aparecer(
                    retraso: _entradaDeTiles + _pasoDeTiles * i,
                    duracion: const Duration(milliseconds: 550),
                    desdeX: 120,
                    desdeY: 0,
                    giro: -8 / 360,
                    curva: Movimiento.rebote,
                    yaEntro: yaEntro,
                    child: TileDeporte(
                      imagen: fotoDeDeporte(d.clave),
                      emoji: _emojiDeDeporte(d.clave),
                      nombre: d.nombre,
                      alTocar: null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ACCESOS RÁPIDOS: buscar una cancha o recorrer las sedes.
class _Accesos extends StatelessWidget {
  const _Accesos({required this.primero, required this.yaEntro});

  /// Cuándo entra el primer acceso; el otro, un paso después.
  final Duration primero;
  final bool yaEntro;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Medidas.s24,
      Medidas.s32,
      Medidas.s24,
      Medidas.s40,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Titulo('ACCESOS RÁPIDOS'),
        const SizedBox(height: Medidas.s12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Aparecer(
                  retraso: primero,
                  yaEntro: yaEntro,
                  child: _Acceso(
                    icono: Icons.search_rounded,
                    titulo: 'Buscar cancha',
                    texto: 'Por sede, fecha y horario',
                    alTocar: () => context.go('/inicio/buscar'),
                  ),
                ),
              ),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: Aparecer(
                  retraso: primero + _pasoDeTiles,
                  yaEntro: yaEntro,
                  child: _Acceso(
                    icono: Icons.location_on_outlined,
                    titulo: 'Ver sedes',
                    texto: 'Horarios y canchas de cada una',
                    alTocar: () => context.go('/sedes'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Una tarjeta de ACCESOS RÁPIDOS: ícono, título y para qué sirve.
class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioLg),
      side: BorderSide(color: p.borderDefault),
    );
    return Semantics(
      button: true,
      child: Material(
        color: p.bgSurfaceRaised,
        shape: forma,
        child: InkWell(
          onTap: alTocar,
          customBorder: forma,
          child: Padding(
            padding: const EdgeInsets.all(Medidas.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, color: p.accentInk),
                const SizedBox(height: Medidas.s16),
                Text(
                  titulo,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  texto,
                  style: Textos.leyenda.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
