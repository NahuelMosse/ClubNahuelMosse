import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/errores_no_manejados.dart';
import '../comun/formato_precio.dart';
import '../espacios/espacio.dart';
import '../espacios/espacios.dart';
import '../espacios/iconos.dart';
import '../reservas/fechas.dart';
import '../sesion/sesion.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'anular_reserva.dart';
import 'estado_reserva_chip.dart';
import 'historial_reservas.dart';

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

  String get _horario {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(reserva.inicio.hour)}:${dos(reserva.inicio.minute)} – '
        '${dos(reserva.fin.hour)}:${dos(reserva.fin.minute)}';
  }

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
                      _TarjetaDatos(
                        reserva: r,
                        horario: _horario,
                        nombreDeporte:
                            _catalogo?.deporte(r.deporte)?.nombre ?? r.deporte,
                      ),
                      if (r.espacioDeBaja) ...[
                        const SizedBox(height: Medidas.s12),
                        _AvisoDeBaja(),
                      ],
                      const SizedBox(height: Medidas.s16),
                      _Trazabilidad(reserva: r),
                      const SizedBox(height: Medidas.s24),
                      if (r.anulable) ...[
                        _anulando
                            ? Semantics(
                                label: 'Anulando la reserva',
                                excludeSemantics: true,
                                child: const SizedBox(
                                  height: Medidas.altoControl,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              )
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

class _TarjetaDatos extends StatelessWidget {
  const _TarjetaDatos({
    required this.reserva,
    required this.horario,
    required this.nombreDeporte,
  });

  final ReservaHistorial reserva;
  final String horario;
  final String nombreDeporte;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$nombreDeporte, sede ${r.sede}, ${r.direccion}, ${pesos(r.total)}, '
          '${r.estado.name}, usuario ${r.usuario}, ${r.espacio}, '
          '${fechaLarga(r.inicio)}, $horario',
      child: Container(
        padding: const EdgeInsets.all(Medidas.s16),
        decoration: BoxDecoration(
          color: p.bgSurfaceRaised,
          borderRadius: BorderRadius.circular(Medidas.radioLg),
          border: Border.all(color: p.borderDefault),
        ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pesos(r.total),
                      style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
                    ),
                    const SizedBox(height: Medidas.s8),
                    EstadoReservaChip(estado: r.estado),
                  ],
                ),
              ],
            ),
            const SizedBox(height: Medidas.s8),
            Text(
              '${r.sede} · ${r.direccion}',
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s12),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: p.textSecondary),
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
            Text(r.espacio, style: Textos.mono.copyWith(color: p.textMuted)),
            const SizedBox(height: Medidas.s8),
            Wrap(
              spacing: Medidas.s16,
              runSpacing: Medidas.s8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: p.textSecondary,
                    ),
                    const SizedBox(width: Medidas.s8),
                    Flexible(
                      child: Text(
                        fechaLarga(r.inicio),
                        style: Textos.leyenda.copyWith(color: p.textSecondary),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 18, color: p.accentInk),
                    const SizedBox(width: Medidas.s8),
                    Flexible(
                      child: Text(
                        horario,
                        style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// La reserva perteneció a un espacio o una sede que ya se dio de baja (FA8): no se le
/// atribuye la anulación al socio.
class _AvisoDeBaja extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Medidas.s16,
        vertical: Medidas.s12,
      ),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: p.textMuted),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Text(
              'Baja del espacio deportivo',
              style: Textos.leyenda.copyWith(color: p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Trazabilidad extends StatelessWidget {
  const _Trazabilidad({required this.reserva});

  final ReservaHistorial reserva;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final motivo = r.motivo;
    final segunda = switch (r.canceladaEn) {
      null => null,
      final cuando => switch (r.estado.name) {
        'anulada' => (
          'Anulada por el administrador',
          Icons.error_outline_rounded,
          p.stateDangerInk,
          'Por ${r.canceladaPorNombre ?? 'un administrador'} · '
              '${_fechaHora(cuando)}'
              '${motivo != null && motivo.trim().isNotEmpty ? ' · $motivo' : ''}',
        ),
        _ => (
          'Cancelada por el usuario',
          Icons.cancel_outlined,
          p.textSecondary,
          'Por ${r.canceladaPorNombre ?? r.usuario} · ${_fechaHora(cuando)}',
        ),
      },
    };
    final aviso = switch ((r.estado.name, r.avisoEnvio, r.avisoEn)) {
      ('anulada', 'enviada', final cuando?) => (
        'Notificación enviada al usuario',
        Icons.notifications_active_outlined,
        p.stateSuccessInk,
        _fechaHora(cuando),
      ),
      ('anulada', final String _, _?) => (
        'Aviso en el centro del usuario',
        Icons.notifications_off_outlined,
        p.textSecondary,
        'El push no salió',
      ),
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioLg),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAZABILIDAD',
            style: Textos.sobretitulo.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: Medidas.s16),
          _Paso(
            icono: Icons.check_circle_outline_rounded,
            color: p.stateSuccessInk,
            titulo: 'Reserva creada',
            subtitulo: 'Por ${r.usuario} · ${_fechaHora(r.creadoEn)}',
          ),
          if (segunda != null) ...[
            const SizedBox(height: Medidas.s12),
            _Paso(
              icono: segunda.$2,
              color: segunda.$3,
              titulo: segunda.$1,
              subtitulo: segunda.$4,
            ),
          ],
          if (aviso != null) ...[
            const SizedBox(height: Medidas.s12),
            _Paso(
              icono: aviso.$2,
              color: aviso.$3,
              titulo: aviso.$1,
              subtitulo: aviso.$4,
            ),
          ],
        ],
      ),
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$titulo, $subtitulo',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  subtitulo,
                  style: Textos.leyenda.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _fechaHora(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
}
