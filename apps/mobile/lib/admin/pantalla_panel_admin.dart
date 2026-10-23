import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../api/cliente_api.dart';
import '../comun/barra_inferior.dart';
import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/estado_vacio.dart';
import '../comun/fallo_de_carga.dart';
import '../comun/formato_precio.dart';
import '../comun/tarjeta_reserva.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../reservas/fechas.dart';
import '../reservas/reservas.dart' show EstadoDeReserva;
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'anular_reserva.dart';
import 'estado_reserva_chip.dart';
import 'historial_reservas.dart';
import 'listado_admin.dart';
import 'pantalla_filtros_reservas.dart';

/// El panel de administración: el historial global de reservas (CU-14), pestaña «Reservas».
class PantallaPanelAdmin extends StatefulWidget {
  const PantallaPanelAdmin({
    super.key,
    required this.historial,
    required this.sedes,
    required this.espacios,
    required this.sesion,
    required this.pendientes,
  });

  final HistorialDeReservas historial;
  final Sedes sedes;
  final Espacios espacios;
  final Sesion sesion;

  /// Los filtros que quedaron aplicados si la sesión venció mientras se miraba esta
  /// pantalla (FA5): se restauran una sola vez.
  final FiltrosDePanelPendientes pendientes;

  @override
  State<PantallaPanelAdmin> createState() => _PantallaPanelAdminState();
}

class _PantallaPanelAdminState extends State<PantallaPanelAdmin> {
  late FiltrosDeHistorial _filtros =
      widget.pendientes.sacar() ?? const FiltrosDeHistorial();
  PaginaDeHistorial? _resultado;
  final _reservas = <ReservaHistorial>[];
  bool _fallo = false;
  bool _cargandoMas = false;
  List<Sede>? _sedesActivas;
  Catalogo? _catalogo;
  late final _busqueda = TextEditingController(text: _filtros.q ?? '');
  final _scroll = ScrollController();
  Timer? _debounce;

  /// Sube con cada pedido: la respuesta de un filtro que ya no se mira se descarta.
  int _pedido = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_alDesplazar);
    _busqueda.addListener(_alEscribir);
    _cargar();
    widget.espacios.catalogo().then((c) {
      if (mounted) setState(() => _catalogo = c);
    }).ignore();
    widget.sedes.activas().then((s) {
      if (mounted) setState(() => _sedesActivas = s);
    }).ignore();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _busqueda.removeListener(_alEscribir);
    _busqueda.dispose();
    super.dispose();
  }

  /// Filtra en vivo mientras se escribe (paso 7), con una pausa corta para no pedir una
  /// página por letra.
  void _alEscribir() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _filtros = _filtros.conBusqueda(_busqueda.text));
      _cargar();
    });
  }

  void _alDesplazar() {
    final resultado = _resultado;
    if (resultado == null ||
        !resultado.hayMasPaginas ||
        _cargandoMas ||
        _fallo) {
      return;
    }
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      _cargarMas();
    }
  }

  Future<void> _cargar() async {
    final pedido = ++_pedido;
    setState(() {
      _resultado = null;
      _reservas.clear();
      _fallo = false;
      _cargandoMas = false;
    });
    Object? error;
    var vencida = false;
    try {
      final pagina = await widget.historial.pagina(_filtros);
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _resultado = pagina;
        _reservas.addAll(pagina.reservas);
      });
      return;
    } on SesionVencida {
      vencida = true;
    } on SinConexion catch (e) {
      error = e;
    } on ErrorDelServidor catch (e) {
      error = e;
    }
    if (!mounted || pedido != _pedido) return;
    setState(() => _fallo = true);
    await avisarFalloDeCarga(
      context,
      sesion: widget.sesion,
      vencida: vencida,
      error: error,
      reintentar: _cargar,
      alVencer: () => widget.pendientes.guardar(_filtros),
    );
  }

  Future<void> _cargarMas() async {
    final resultado = _resultado;
    if (resultado == null) return;
    final pedido = _pedido;
    setState(() => _cargandoMas = true);
    try {
      final siguiente = await widget.historial.pagina(
        _filtros,
        pagina: resultado.pagina + 1,
      );
      if (!mounted || pedido != _pedido) return;
      setState(() {
        _resultado = siguiente;
        // Con la paginación por OFFSET, una reserva nueva o anulada entre dos páginas
        // corre las filas: se descartan las que ya están.
        final vistas = {for (final r in _reservas) r.id};
        _reservas.addAll(siguiente.reservas.where((r) => vistas.add(r.id)));
      });
    } on Exception {
      // Sin red o con el servidor caído: lo que ya se cargó sigue viéndose, y el
      // desplazamiento vuelve a intentar más adelante.
    } finally {
      if (mounted && pedido == _pedido) setState(() => _cargandoMas = false);
    }
  }

  void _elegirEstado(EstadoDeReserva? estado) {
    if (_filtros.estado == estado) return;
    setState(() => _filtros = _filtros.conEstado(estado));
    _cargar();
  }

  void _limpiarFiltros() {
    _debounce?.cancel();
    _busqueda.clear();
    setState(() => _filtros = const FiltrosDeHistorial());
    _cargar();
  }

  Future<void> _abrirFiltros() async {
    // Se precargan al abrir la pantalla: si el servidor falla ahora, el panel abre igual
    // con lo que ya se tenía.
    var sedes = _sedesActivas;
    var catalogo = _catalogo;
    try {
      sedes ??= await widget.sedes.activas();
      catalogo ??= await widget.espacios.catalogo();
    } on Exception {
      // Sin la lista, el panel abre sin esas opciones; el resto de los filtros sigue.
    }
    if (!mounted) return;
    setState(() {
      _sedesActivas = sedes;
      _catalogo = catalogo;
    });
    final elegidos = await abrirFiltrosDeReservas(
      context,
      filtros: _filtros,
      sedes: sedes ?? const [],
      catalogo: catalogo ?? const Catalogo([]),
    );
    if (elegidos == null || !mounted) return;
    _debounce?.cancel();
    _busqueda.text = elegidos.q ?? '';
    setState(() => _filtros = elegidos);
    unawaited(_cargar());
  }

  Future<void> _abrirDetalle(ReservaHistorial r) async {
    await context.push<bool>('/admin/reserva/${r.id}', extra: (r, _filtros));
    if (mounted) unawaited(_cargar());
  }

  /// La anulación de [r] está en camino: el listado no responde hasta que termine.
  bool _anulando = false;

  Future<void> _anular(ReservaHistorial r) async {
    if (_anulando) return;
    final resultado = await anularReserva(
      context,
      reserva: r,
      historial: widget.historial,
      sesion: widget.sesion,
      filtros: _filtros,
      pendientes: widget.pendientes,
      enviando: (v) {
        if (mounted) setState(() => _anulando = v);
      },
    );
    if (resultado != ResultadoDeAnulacion.nada && mounted) {
      unawaited(_cargar());
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final resultado = _resultado;
    final catalogo = _catalogo;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraAdmin(actual: SeccionAdmin.reservas),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s24,
                  Medidas.s24,
                  Medidas.s16,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EncabezadoAdmin(
                        titulo: 'Reservas',
                        sesion: widget.sesion,
                      ),
                      const SizedBox(height: Medidas.s16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CampoTexto(
                              etiquetaAccesible: 'Buscar reserva',
                              // Con el botón Filtros al lado, en 360 «Buscar reserva» no entra entero.
                              placeholder:
                                  MediaQuery.sizeOf(context).width < 400
                                  ? 'Buscar'
                                  : 'Buscar reserva',
                              controlador: _busqueda,
                              accionFinal: Icon(
                                Icons.search_rounded,
                                color: p.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(width: Medidas.s8),
                          Flexible(
                            child: BotonContorno(
                              texto: 'Filtros',
                              icono: Icons.tune_rounded,
                              compacto: true,
                              expandir: false,
                              alTocar: _abrirFiltros,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Medidas.s16),
                      _Pestanas(
                        elegido: _filtros.estado,
                        contadores: resultado?.contadores,
                        alElegir: _elegirEstado,
                      ),
                      const SizedBox(height: Medidas.s12),
                      if (resultado != null)
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _filtros.hayFiltros
                                    ? '${resultado.total} '
                                          '${resultado.total == 1 ? 'RESULTADO' : 'RESULTADOS'}'
                                    : '${resultado.total} '
                                          '${resultado.total == 1 ? 'RESERVA EN TOTAL' : 'RESERVAS EN TOTAL'}',
                                style: Textos.sobretitulo.copyWith(
                                  color: p.textMuted,
                                ),
                              ),
                            ),
                            // Con cero resultados, «Limpiar filtros» ya está en el estado
                            // vacío de abajo: no se duplica el botón.
                            if (_filtros.hayFiltros && resultado.total > 0)
                              BotonTexto(
                                texto: 'LIMPIAR FILTROS',
                                alTocar: _limpiarFiltros,
                              ),
                          ],
                        ),
                      const SizedBox(height: Medidas.s8),
                    ],
                  ),
                ),
              ),
              if (resultado == null && !_fallo)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Medidas.s40),
                    child: Column(
                      children: [
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            'Cargando reservas…',
                            style: Textos.sobretitulo.copyWith(
                              color: p.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (resultado == null && _fallo)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(Medidas.s24),
                    child: Center(
                      child: BotonTexto(texto: 'REINTENTAR', alTocar: _cargar),
                    ),
                  ),
                ),
              if (resultado != null && resultado.total == 0)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: Medidas.s24),
                  sliver: SliverToBoxAdapter(
                    child: _filtros.hayFiltros
                        ? EstadoVacio(
                            titulo: 'Sin resultados',
                            texto:
                                'Ninguna reserva coincide con los filtros '
                                'aplicados.',
                            accion: 'LIMPIAR FILTROS',
                            alTocar: _limpiarFiltros,
                          )
                        : const EstadoVacio(
                            titulo: 'No hay reservas',
                            texto:
                                'Todavía no se registró ninguna reserva en '
                                'el sistema.',
                          ),
                  ),
                ),
              if (resultado != null && resultado.total > 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s24,
                    0,
                    Medidas.s24,
                    Medidas.s40,
                  ),
                  sliver: SliverList.builder(
                    itemCount: _reservas.length,
                    itemBuilder: (context, i) {
                      final r = _reservas[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: Medidas.s12),
                        child: _TarjetaReservaAdmin(
                          reserva: r,
                          catalogo: catalogo,
                          alTocar: () => _abrirDetalle(r),
                          alAnular: _anulando ? null : () => _anular(r),
                        ),
                      );
                    },
                  ),
                ),
              if (_cargandoMas)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: Medidas.s16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({
    required this.elegido,
    required this.contadores,
    required this.alElegir,
  });

  final EstadoDeReserva? elegido;
  final Contadores? contadores;
  final ValueChanged<EstadoDeReserva?> alElegir;

  @override
  Widget build(BuildContext context) {
    final c = contadores;
    Widget pestana(String texto, EstadoDeReserva? valor, int? cuenta) {
      final activa = elegido == valor;
      final etiqueta = cuenta == null ? texto : '$texto ($cuenta)';
      final p = context.paleta;
      return Padding(
        padding: const EdgeInsets.only(right: Medidas.s8),
        child: Semantics(
          button: true,
          selected: activa,
          excludeSemantics: true,
          label: etiqueta,
          child: Material(
            color: activa ? p.accentBase : p.bgSurfaceRaised,
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: () => alElegir(valor),
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Medidas.s16,
                  vertical: Medidas.s12,
                ),
                child: Text(
                  etiqueta,
                  style: Textos.cuerpoFuerte.copyWith(
                    color: activa ? p.accentOn : p.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          pestana('Todas', null, c?.todas),
          pestana('Activas', EstadoDeReserva.activa, c?.activas),
          pestana('Completadas', EstadoDeReserva.completada, c?.completadas),
          pestana('Anuladas', EstadoDeReserva.anulada, c?.anuladas),
        ],
      ),
    );
  }
}

class _TarjetaReservaAdmin extends StatelessWidget {
  const _TarjetaReservaAdmin({
    required this.reserva,
    required this.catalogo,
    required this.alTocar,
    required this.alAnular,
  });

  final ReservaHistorial reserva;
  final Catalogo? catalogo;
  final VoidCallback alTocar;

  /// `null` deshabilita ANULAR RESERVA (hay otra anulación en camino).
  final VoidCallback? alAnular;

  String get _horario {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(reserva.inicio.hour)}:${dos(reserva.inicio.minute)} – '
        '${dos(reserva.fin.hour)}:${dos(reserva.fin.minute)}';
  }

  // Con cualquier agrandado del texto, precio y estado ya no entran junto al nombre en 360.
  bool _grande(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) > 13;

  Widget _precioYEstado(Paleta p) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        pesos(reserva.total),
        style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
      ),
      const SizedBox(height: Medidas.s4),
      EstadoReservaChip(estado: reserva.estado),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final nombreDeporte = catalogo?.deporte(r.deporte)?.nombre ?? r.deporte;
    final semantica =
        '$nombreDeporte, ${r.sede}, ${r.usuario}, '
        '${fechaLarga(r.inicio)}, $_horario, ${pesos(r.total)}, '
        '${r.estado.name}'
        '${r.espacioDeBaja ? ', baja del espacio deportivo' : ''}';
    final anular = alAnular;
    return Material(
      color: p.bgSurfaceRaised,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        side: BorderSide(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: semantica,
            excludeSemantics: true,
            child: InkWell(
              onTap: alTocar,
              child: Padding(
                padding: const EdgeInsets.all(Medidas.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          iconoDeDeporte(r.deporte),
                          size: 20,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: Medidas.s8),
                        Expanded(
                          child: Text(
                            nombreDeporte,
                            style: Textos.titulo.copyWith(color: p.textPrimary),
                          ),
                        ),
                        // Con el texto muy agrandado, precio y estado bajan debajo del
                        // nombre en vez de disputarle el ancho.
                        if (!_grande(context)) ...[
                          const SizedBox(width: Medidas.s8),
                          _precioYEstado(p),
                        ],
                      ],
                    ),
                    if (_grande(context)) ...[
                      const SizedBox(height: Medidas.s8),
                      _precioYEstado(p),
                    ],
                    const SizedBox(height: Medidas.s4),
                    Text(
                      '${r.sede} · ${r.direccion}',
                      style: Textos.leyenda.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: Medidas.s12),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: p.textSecondary,
                        ),
                        const SizedBox(width: Medidas.s8),
                        Expanded(
                          child: Text(
                            r.usuario,
                            style: Textos.cuerpo.copyWith(color: p.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Medidas.s8),
                    Text(
                      r.espacio,
                      style: Textos.mono.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: Medidas.s8),
                    FechaYHorario(
                      fecha: fechaLarga(r.inicio),
                      horario: _horario,
                      separacionVertical: Medidas.s4,
                      alineacion: WrapCrossAlignment.start,
                    ),
                    if (r.espacioDeBaja) ...[
                      const SizedBox(height: Medidas.s8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: p.textMuted,
                          ),
                          const SizedBox(width: Medidas.s4),
                          Flexible(
                            child: Text(
                              'Baja del espacio deportivo',
                              style: Textos.leyenda.copyWith(
                                color: p.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (r.anulable)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s16,
                0,
                Medidas.s16,
                Medidas.s16,
              ),
              child: BotonContorno(
                texto: 'ANULAR RESERVA',
                peligro: true,
                etiquetaAccesible:
                    'Anular la reserva de ${r.usuario}, $nombreDeporte, '
                    '${fechaLarga(r.inicio)}, $_horario',
                alTocar: anular,
              ),
            ),
        ],
      ),
    );
  }
}
