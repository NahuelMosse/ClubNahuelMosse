import 'package:flutter/material.dart';

import '../comun/formato_fecha.dart';
import '../comun/transiciones.dart';
import '../espacios/espacio.dart';
import '../reservas/reservas.dart';
import '../sedes/sede.dart';
import '../tema/tokens.dart';
import 'acciones_de_filtros.dart';
import 'cabecera_de_filtros.dart';
import 'filtro_de_deporte.dart';
import 'filtro_de_estado.dart';
import 'filtro_de_sede.dart';
import 'historial_reservas.dart';
import 'rango_de_fechas_de_filtro.dart';
import 'titulo_de_filtro.dart';

/// El panel de Filtros del historial global (CU-14, paso 5): sede, deporte, estado y rango
/// de fechas, más el buscador. Abre con lo ya aplicado y sólo devuelve algo al confirmar.
Future<FiltrosDeHistorial?> abrirFiltrosDeReservas(
  BuildContext context, {
  required FiltrosDeHistorial filtros,
  required List<Sede> sedes,
  required Catalogo catalogo,
}) => Navigator.of(context).push<FiltrosDeHistorial>(
  rutaQueSube<FiltrosDeHistorial>(
    context,
    builder: (context) =>
        _PanelDeFiltros(filtros: filtros, sedes: sedes, catalogo: catalogo),
  ),
);

class _PanelDeFiltros extends StatefulWidget {
  const _PanelDeFiltros({
    required this.filtros,
    required this.sedes,
    required this.catalogo,
  });

  final FiltrosDeHistorial filtros;
  final List<Sede> sedes;
  final Catalogo catalogo;

  @override
  State<_PanelDeFiltros> createState() => _PanelDeFiltrosState();
}

class _PanelDeFiltrosState extends State<_PanelDeFiltros> {
  late String? _sedeId = widget.filtros.sedeId;
  late String? _deporte = widget.filtros.deporte;
  late EstadoDeReserva? _estado = widget.filtros.estado;
  late String? _q = widget.filtros.q;
  late final _desde = TextEditingController(
    text: switch (widget.filtros.desde) {
      final d? => formatearFecha(d),
      null => '',
    },
  );
  late final _hasta = TextEditingController(
    text: switch (widget.filtros.hasta) {
      final d? => formatearFecha(d),
      null => '',
    },
  );

  @override
  void initState() {
    super.initState();
    _desde.addListener(() => setState(() {}));
    _hasta.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _desde.dispose();
    _hasta.dispose();
    super.dispose();
  }

  DateTime? get _fechaDesde =>
      _desde.text.trim().isEmpty ? null : leerFecha(_desde.text);
  DateTime? get _fechaHasta =>
      _hasta.text.trim().isEmpty ? null : leerFecha(_hasta.text);

  /// Hay texto en el campo y no es una fecha que exista.
  bool _noEsFecha(TextEditingController c) =>
      c.text.trim().isNotEmpty && leerFecha(c.text) == null;

  bool get _hayFechaInvalida => _noEsFecha(_desde) || _noEsFecha(_hasta);

  bool get _rangoInvalido {
    final d = _fechaDesde;
    final h = _fechaHasta;
    return d != null && h != null && d.isAfter(h);
  }

  void _limpiar() {
    setState(() {
      _sedeId = null;
      _deporte = null;
      _estado = null;
      _desde.clear();
      _hasta.clear();
      _q = null;
    });
  }

  void _aplicar() {
    if (_rangoInvalido || _hayFechaInvalida) return;
    Navigator.of(context).pop(
      FiltrosDeHistorial(
        estado: _estado,
        sedeId: _sedeId,
        deporte: _deporte,
        desde: _fechaDesde,
        hasta: _fechaHasta,
        q: _q,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgSurfaceRaised,
      body: SafeArea(
        child: Column(
          children: [
            const CabeceraDeFiltros(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s24,
                  Medidas.s8,
                  Medidas.s24,
                  Medidas.s24,
                ),
                children: [
                  TituloDeFiltro('SEDE'),
                  const SizedBox(height: Medidas.s8),
                  FiltroDeSede(
                    sedes: widget.sedes,
                    elegida: _sedeId,
                    alElegir: (sede) => setState(
                      () => _sedeId = _sedeId == sede.id ? null : sede.id,
                    ),
                  ),
                  const SizedBox(height: Medidas.s20),
                  TituloDeFiltro('DEPORTE'),
                  const SizedBox(height: Medidas.s8),
                  FiltroDeDeporte(
                    deportes: widget.catalogo.deportes,
                    elegido: _deporte,
                    alElegir: (deporte) => setState(
                      () => _deporte = _deporte == deporte.clave
                          ? null
                          : deporte.clave,
                    ),
                  ),
                  const SizedBox(height: Medidas.s20),
                  TituloDeFiltro('ESTADO'),
                  const SizedBox(height: Medidas.s8),
                  FiltroDeEstado(
                    elegido: _estado,
                    alElegir: (e) => setState(
                      () => _estado = e == null || _estado == e ? null : e,
                    ),
                  ),
                  const SizedBox(height: Medidas.s20),
                  TituloDeFiltro('RANGO DE FECHAS'),
                  const SizedBox(height: Medidas.s8),
                  // En un teléfono chico dos campos lado a lado no dejan ver la fecha
                  // entera; se apilan.
                  RangoDeFechasDeFiltro(
                    desde: _desde,
                    hasta: _hasta,
                    desdeInvalida: _noEsFecha(_desde),
                    hastaInvalida: _noEsFecha(_hasta),
                    rangoInvalido: _rangoInvalido,
                  ),
                ],
              ),
            ),
            AccionesDeFiltros(
              alLimpiar: _limpiar,
              alAplicar: _rangoInvalido || _hayFechaInvalida ? null : _aplicar,
            ),
          ],
        ),
      ),
    );
  }
}
