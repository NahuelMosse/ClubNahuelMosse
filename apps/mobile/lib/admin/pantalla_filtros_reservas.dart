import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../comun/chip_elegible.dart';
import '../comun/formato_fecha.dart';
import '../comun/transiciones.dart';
import '../espacios/espacio.dart';
import '../reservas/reservas.dart';
import '../sedes/sede.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'historial_reservas.dart';

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
  late int? _sedeId = widget.filtros.sedeId;
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
    Widget chip(String texto, bool elegido, VoidCallback alTocar) =>
        ChipElegible(
          texto: texto,
          elegido: elegido,
          alTocar: alTocar,
          estilo: Textos.cuerpo,
          relleno: const EdgeInsets.symmetric(
            horizontal: Medidas.s16,
            vertical: Medidas.s8,
          ),
          fondoApagado: p.bgSurface,
        );
    return Scaffold(
      backgroundColor: p.bgSurfaceRaised,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s24,
                Medidas.s16,
                Medidas.s16,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        'Filtros',
                        style: Textos.h2.copyWith(color: p.textPrimary),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close_rounded),
                    color: p.textSecondary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s24,
                  Medidas.s8,
                  Medidas.s24,
                  Medidas.s24,
                ),
                children: [
                  _Titulo('SEDE'),
                  const SizedBox(height: Medidas.s8),
                  Wrap(
                    spacing: Medidas.s8,
                    runSpacing: Medidas.s8,
                    children: [
                      for (final sede in widget.sedes)
                        chip(
                          sede.nombre,
                          _sedeId == sede.id,
                          () => setState(
                            () => _sedeId = _sedeId == sede.id ? null : sede.id,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Medidas.s20),
                  _Titulo('DEPORTE'),
                  const SizedBox(height: Medidas.s8),
                  Wrap(
                    spacing: Medidas.s8,
                    runSpacing: Medidas.s8,
                    children: [
                      for (final deporte in widget.catalogo.deportes)
                        chip(
                          deporte.nombre,
                          _deporte == deporte.clave,
                          () => setState(
                            () => _deporte = _deporte == deporte.clave
                                ? null
                                : deporte.clave,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Medidas.s20),
                  _Titulo('ESTADO'),
                  const SizedBox(height: Medidas.s8),
                  Wrap(
                    spacing: Medidas.s8,
                    runSpacing: Medidas.s8,
                    children: [
                      chip(
                        'Todas',
                        _estado == null,
                        () => setState(() => _estado = null),
                      ),
                      for (final e in const [
                        EstadoDeReserva.activa,
                        EstadoDeReserva.completada,
                        EstadoDeReserva.anulada,
                      ])
                        chip(
                          switch (e) {
                            EstadoDeReserva.activa => 'Activas',
                            EstadoDeReserva.completada => 'Completadas',
                            _ => 'Anuladas',
                          },
                          _estado == e,
                          () =>
                              setState(() => _estado = _estado == e ? null : e),
                        ),
                    ],
                  ),
                  const SizedBox(height: Medidas.s20),
                  _Titulo('RANGO DE FECHAS'),
                  const SizedBox(height: Medidas.s8),
                  // En un teléfono chico dos campos lado a lado no dejan ver la fecha
                  // entera; se apilan.
                  LayoutBuilder(
                    builder: (context, caja) {
                      final desde = CampoTexto(
                        etiqueta: 'Desde',
                        etiquetaAccesible: 'Desde',
                        placeholder: 'DD / MM / AAAA',
                        controlador: _desde,
                        teclado: TextInputType.number,
                        formateadores: const [FormatoFecha()],
                        accionFinal: Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: p.textMuted,
                        ),
                        error: _noEsFecha(_desde)
                            ? 'Fecha inválida'
                            : _rangoInvalido
                            ? 'Desde no puede ser posterior a Hasta'
                            : null,
                      );
                      final hasta = CampoTexto(
                        etiqueta: 'Hasta',
                        etiquetaAccesible: 'Hasta',
                        placeholder: 'DD / MM / AAAA',
                        controlador: _hasta,
                        teclado: TextInputType.number,
                        formateadores: const [FormatoFecha()],
                        accionFinal: Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: p.textMuted,
                        ),
                        error: _noEsFecha(_hasta)
                            ? 'Fecha inválida'
                            : _rangoInvalido
                            ? (caja.maxWidth < 330
                                  ? 'Hasta no puede ser anterior a Desde'
                                  : ' ')
                            : null,
                      );
                      if (caja.maxWidth < 330) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            desde,
                            const SizedBox(height: Medidas.s12),
                            hasta,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: desde),
                          const SizedBox(width: Medidas.s12),
                          Expanded(child: hasta),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s24,
                0,
                Medidas.s24,
                Medidas.s24,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: BotonContorno(texto: 'LIMPIAR', alTocar: _limpiar),
                  ),
                  const SizedBox(width: Medidas.s12),
                  Expanded(
                    child: BotonPrimario(
                      texto: 'APLICAR',
                      alTocar: _rangoInvalido || _hayFechaInvalida
                          ? null
                          : _aplicar,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: Textos.sobretitulo.copyWith(color: context.paleta.textMuted),
  );
}
