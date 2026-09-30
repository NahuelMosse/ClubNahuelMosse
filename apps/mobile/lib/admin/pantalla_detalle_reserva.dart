import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/formato_precio.dart';
import '../espacios/iconos.dart';
import '../reservas/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'estado_reserva_chip.dart';
import 'historial_reservas.dart';

/// El detalle de sólo lectura de una reserva del historial global (CU-14): datos y
/// trazabilidad. La acción de anular (CU-15) todavía no vive acá.
class PantallaDetalleReserva extends StatelessWidget {
  const PantallaDetalleReserva({super.key, required this.reserva});

  final ReservaHistorial reserva;

  String get _horario {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(reserva.inicio.hour)}:${dos(reserva.inicio.minute)} – '
        '${dos(reserva.fin.hour)}:${dos(reserva.fin.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Scaffold(
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
                    onPressed: () => Navigator.of(context).pop(),
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
                    _TarjetaDatos(reserva: r, horario: _horario),
                    if (r.espacioDeBaja) ...[
                      const SizedBox(height: Medidas.s12),
                      _AvisoDeBaja(),
                    ],
                    const SizedBox(height: Medidas.s16),
                    _Trazabilidad(reserva: r),
                    const SizedBox(height: Medidas.s24),
                    BotonContorno(
                      texto: 'VOLVER AL LISTADO',
                      alTocar: () => Navigator.of(context).pop(),
                    ),
                    // La acción de anular (CU-15) va acá, sobre una reserva vigente.
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaDatos extends StatelessWidget {
  const _TarjetaDatos({required this.reserva, required this.horario});

  final ReservaHistorial reserva;
  final String horario;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${r.deporte}, sede ${r.sede}, ${r.direccion}, ${pesos(r.total)}, '
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
                    r.deporte,
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
            Text(
              r.espacio,
              style: Textos.mono.copyWith(color: p.textMuted),
            ),
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
                    Text(
                      fechaLarga(r.inicio),
                      style: Textos.leyenda.copyWith(color: p.textSecondary),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: p.accentInk,
                    ),
                    const SizedBox(width: Medidas.s8),
                    Text(
                      horario,
                      style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
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
