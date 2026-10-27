import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/barra_inferior.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../reservas/reservas.dart' show EstadoDeReserva;
import '../sedes/sede.dart';
import '../sedes/sedes.dart';
import '../sesion/fallo_de_carga.dart';
import '../sesion/sesion.dart';
import '../tema/tokens.dart';
import 'anular_reserva.dart';
import 'cuerpo_del_panel_admin.dart';
import 'encabezado_de_reservas.dart';
import 'historial_paginado.dart';
import 'historial_reservas.dart';
import 'opciones_de_filtros_del_panel.dart';
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
  late final _paginas = HistorialPaginado(widget.historial);
  List<Sede>? _sedesActivas;
  Catalogo? _catalogo;
  late final _busqueda = TextEditingController(text: _filtros.q ?? '');
  final _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _paginas.addListener(() => setState(() {}));
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
    _paginas.dispose();
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
    if (!_paginas.faltaCargarMas) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      _paginas.cargarMas(_filtros);
    }
  }

  Future<void> _cargar() async {
    final falla = await _paginas.cargar(_filtros);
    if (falla == null || !mounted) return;
    await avisarFalloDeCarga(
      context,
      sesion: widget.sesion,
      vencida: falla.vencida,
      error: falla.error,
      reintentar: _cargar,
      alVencer: () => widget.pendientes.guardar(_filtros),
    );
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
    final (sedes, catalogo) = await opcionesDeFiltrosDelPanel(
      widget.sedes,
      widget.espacios,
      sedesActivas: _sedesActivas,
      catalogo: _catalogo,
    );
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
    final resultado = _paginas.resultado;
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
              EncabezadoDeReservas(
                sesion: widget.sesion,
                busqueda: _busqueda,
                filtros: _filtros,
                resultado: resultado,
                alAbrirFiltros: _abrirFiltros,
                alElegirEstado: _elegirEstado,
                alLimpiarFiltros: _limpiarFiltros,
              ),
              ...cuerpoDelPanelAdmin(
                resultado: resultado,
                fallo: _paginas.fallo,
                cargandoMas: _paginas.cargandoMas,
                hayFiltros: _filtros.hayFiltros,
                reservas: _paginas.reservas,
                catalogo: _catalogo,
                alReintentar: _cargar,
                alLimpiarFiltros: _limpiarFiltros,
                alTocar: _abrirDetalle,
                alAnular: _anulando ? null : _anular,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
