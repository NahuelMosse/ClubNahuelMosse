import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/en_curso.dart';
import '../comun/errores_no_manejados.dart';
import '../comun/fechas.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'anular_reserva.dart';
import 'historial_reservas.dart';
import 'tarjeta_datos_de_reserva.dart';
import 'aviso_de_baja.dart';
import 'trazabilidad.dart';

/// El detalle de una reserva del historial global (CU-14): datos y trazabilidad, y si la
/// reserva se puede anular (CU-15), la acción de anularla. Muestra lo que el servidor dice al
/// abrirla, no lo que el listado tenía. Mientras la anulación está en camino no se puede salir.
/// Al volver avisa con `true` que la reserva cambió.
class PantallaDetalleReserva extends StatefulWidget {
  const PantallaDetalleReserva({
    super.key,
    required this.reserva,
    required this.historial,
    required this.sesion,
    required this.espacios,
    required this.filtros,
    required this.pendientes,
  });

  /// La reserva como la mostraba el listado, hasta que llegue la vigente.
  final ReservaHistorial reserva;
  final HistorialDeReservas historial;
  final Sesion sesion;
  final Espacios espacios;

  /// Los filtros del listado de donde se vino y dónde se guardan si la sesión vence.
  final FiltrosDeHistorial filtros;
  final FiltrosDePanelPendientes pendientes;

  @override
  State<PantallaDetalleReserva> createState() => _PantallaDetalleReservaState();
}

class _PantallaDetalleReservaState extends State<PantallaDetalleReserva> {
  bool _anulando = false;
  late ReservaHistorial _vigente = widget.reserva;
  Catalogo? _catalogo;

  ReservaHistorial get reserva => _vigente;

  @override
  void initState() {
    super.initState();
    widget.historial.detalle(widget.reserva.id).then((r) {
      if (mounted && r != null) setState(() => _vigente = r);
    }, onError: registrarError);
    widget.espacios.catalogo().then((c) {
      if (mounted) setState(() => _catalogo = c);
    }, onError: registrarError);
  }

  Future<void> _anular() async {
    if (_anulando) return;
    final resultado = await anularReserva(
      context,
      reserva: reserva,
      historial: widget.historial,
      sesion: widget.sesion,
      filtros: widget.filtros,
      pendientes: widget.pendientes,
      enviando: (v) {
        if (mounted) setState(() => _anulando = v);
      },
    );
    if (resultado != ResultadoDeAnulacion.nada && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  String get _horario => rangoDeHoras(reserva.inicio, reserva.fin);

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return PopScope(
      canPop: !_anulando,
      child: Scaffold(
        backgroundColor: p.bgBase,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Medidas.s8,
                  Medidas.s16,
                  Medidas.s24,
                  Medidas.s8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _anulando
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: 'Volver',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: p.textPrimary,
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Detalle de reserva',
                          style: Textos.h2.copyWith(color: p.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Medidas.s24,
                    0,
                    Medidas.s24,
                    Medidas.s24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TarjetaDatosDeReserva(
                        reserva: r,
                        horario: _horario,
                        nombreDeporte:
                            _catalogo?.deporte(r.deporte)?.nombre ?? r.deporte,
                      ),
                      if (r.espacioDeBaja) ...[
                        const SizedBox(height: Medidas.s12),
                        AvisoDeBaja(),
                      ],
                      const SizedBox(height: Medidas.s16),
                      Trazabilidad(reserva: r),
                      const SizedBox(height: Medidas.s24),
                      if (r.anulable) ...[
                        _anulando
                            ? const EnCurso('Anulando la reserva')
                            : BotonContorno(
                                texto: 'ANULAR RESERVA',
                                peligro: true,
                                etiquetaAccesible:
                                    'Anular la reserva de ${r.usuario}',
                                alTocar: _anular,
                              ),
                        const SizedBox(height: Medidas.s12),
                      ],
                      BotonContorno(
                        texto: 'VOLVER AL LISTADO',
                        alTocar: _anulando
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
