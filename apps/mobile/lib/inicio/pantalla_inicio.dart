import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/dialogo_error.dart';
import '../sesion/fallo_de_carga.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../notificaciones/campana.dart';
import '../notificaciones/centro.dart';
import '../reservas/pantalla_confirmar_cambio.dart';
import '../reservas/pantalla_mis_reservas.dart';
import '../reservas/reservas.dart';
import '../sedes/fotos.dart';
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../sesion/tarjeta_cuenta.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

typedef _Datos = ({Reserva? proxima, Catalogo catalogo, List<Sede> sedes});

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

  @override
  void initState() {
    super.initState();
    widget.reservas.addListener(_alCambiarLasReservas);
    _cargar();
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
      final catalogo = await widget.espacios.catalogo();
      final proximas = await widget.reservas.mias(historial: false);
      final sedes = await widget.sedes.activas();
      if (mounted && pedido == _pedido) {
        setState(
          () => _datos = (
            proxima: proximas.firstOrNull,
            catalogo: catalogo,
            sedes: sedes,
          ),
        );
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

  /// Vuelve a leer sin avisos: si no se puede, queda lo que había.
  Future<void> _releerSinAvisar() async {
    final pedido = ++_pedido;
    try {
      final catalogo = await widget.espacios.catalogo();
      final proximas = await widget.reservas.mias(historial: false);
      final sedes = await widget.sedes.activas();
      if (mounted && pedido == _pedido) {
        setState(
          () => _datos = (
            proxima: proximas.firstOrNull,
            catalogo: catalogo,
            sedes: sedes,
          ),
        );
      }
    } on Exception {
      // Sin red o con el servidor caído, lo que había sigue siendo lo mejor que hay.
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
    setState(() => _cancelando = r.id);
    while (mounted) {
      Object? fallo;
      try {
        await widget.reservas.cancelar(r);
        if (!mounted) return;
        setState(() {
          if (_datos case final datos?) {
            _datos = (
              proxima: null,
              catalogo: datos.catalogo,
              sedes: datos.sedes,
            );
          }
          _cancelando = null;
        });
        await mostrarCancelada(context);
        if (mounted) await _cargar(deCero: false);
        return;
      } on ReservaCambiada {
        if (!mounted) return;
        setState(() => _cancelando = null);
        await mostrarCambioMientrasTanto(context);
        if (mounted) await _cargar(deCero: false);
        return;
      } on SesionVencida {
        if (!mounted) return;
        setState(() => _cancelando = null);
        await mostrarSesionVencida(context);
        if (mounted) await cerrarSesion(context, widget.sesion);
        return;
      } on SinConexion catch (e) {
        fallo = e;
      } on ErrorDelServidor catch (e) {
        fallo = e;
      }
      if (!mounted) return;
      setState(() => _cancelando = null);
      final otraVez = await mostrarErrorDeRed(context, fallo);
      if (!mounted) return;
      if (!otraVez) {
        // Si el corte llegó después de que el servidor la canceló, la lectura lo muestra.
        await _releerSinAvisar();
        return;
      }
      setState(() => _cancelando = r.id);
    }
  }

  /// Abre la grilla para cambiar [r] de horario y, al volver, lee el Home de nuevo.
  Future<void> _modificar(Reserva r) async {
    final resultado = await context.push<ResultadoDeModificar>(
      '/reservas/${r.id}/modificar?desde=inicio',
      extra: r,
    );
    if (!mounted) return;
    if (resultado == ResultadoDeModificar.modificada) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reserva modificada')));
    }
    await _releerSinAvisar();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final datos = _datos;
    final proxima = datos?.proxima;
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                _Hero(
                  sesion: widget.sesion,
                  centro: widget.centro,
                  resumen: datos == null ? null : _resumen(datos.sedes),
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
                      child: BotonTexto(texto: 'REINTENTAR', alTocar: _cargar),
                    ),
                  ),
                if (datos != null) ...[
                  if (proxima != null)
                    _Proxima(
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
                  _Deportes(catalogo: datos.catalogo),
                  const _Accesos(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _resumen(List<Sede> sedes) {
  final canchas = sedes.fold(0, (total, s) => total + s.canchas);
  final cuantasSedes = sedes.length == 1 ? 'sede' : 'sedes';
  final cuantasCanchas = canchas == 1 ? 'cancha' : 'canchas';
  return '${sedes.length} $cuantasSedes · $canchas $cuantasCanchas · '
      'disponibilidad en tiempo real';
}

/// La portada: el saludo, la cuenta y el pedido del día. Va sobre una foto, así que sus
/// colores son los del modo oscuro en los dos modos.
class _Hero extends StatelessWidget {
  const _Hero({required this.sesion, required this.resumen, this.centro});

  final Sesion sesion;

  final CentroDeNotificaciones? centro;

  /// `null` mientras se lee.
  final String? resumen;

  @override
  Widget build(BuildContext context) {
    const tinta = Paleta.oscura;
    final arriba = MediaQuery.paddingOf(context).top;
    final texto = resumen;
    return FotoConVelo(
      imagen: fotoDeDeporte('Futbol'),
      child: Padding(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUENOS DÍAS,',
                        style: Textos.sobretitulo.copyWith(
                          color: tinta.accentBase,
                        ),
                      ),
                      const SizedBox(height: Medidas.s4),
                      ListenableBuilder(
                        listenable: sesion,
                        builder: (context, _) => Text(
                          sesion.perfil?.nombre ?? '',
                          style: Textos.h1.copyWith(color: tinta.textPrimary),
                        ),
                      ),
                    ],
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
                style: Textos.display.copyWith(color: tinta.textPrimary),
              ),
            ),
            if (texto != null) ...[
              const SizedBox(height: Medidas.s8),
              Text(
                texto,
                style: Textos.leyenda.copyWith(color: tinta.textSecondary),
              ),
            ],
          ],
        ),
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
          alCancelar: alCancelar,
          alModificar: alModificar,
        ),
      ],
    ),
  );
}

/// Los deportes del club. Informan; no llevan a ningún lado.
class _Deportes extends StatelessWidget {
  const _Deportes({required this.catalogo});

  final Catalogo catalogo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
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
                for (final d in catalogo.deportes) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Medidas.s16,
                      vertical: Medidas.s12,
                    ),
                    decoration: BoxDecoration(
                      color: p.bgSurfaceRaised,
                      borderRadius: BorderRadius.circular(Medidas.radioPill),
                      border: Border.all(color: p.borderDefault),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconoDeDeporte(d.clave),
                          size: 18,
                          color: p.accentInk,
                        ),
                        const SizedBox(width: Medidas.s8),
                        Text(
                          d.nombre,
                          style: Textos.cuerpoFuerte.copyWith(
                            color: p.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Medidas.s8),
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
  const _Accesos();

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
                child: _Acceso(
                  icono: Icons.search_rounded,
                  titulo: 'Buscar cancha',
                  texto: 'Por sede, fecha y horario',
                  alTocar: () => context.go('/inicio/buscar'),
                ),
              ),
              const SizedBox(width: Medidas.s12),
              Expanded(
                child: _Acceso(
                  icono: Icons.location_on_outlined,
                  titulo: 'Ver sedes',
                  texto: 'Horarios y canchas de cada una',
                  alTocar: () => context.go('/sedes'),
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
