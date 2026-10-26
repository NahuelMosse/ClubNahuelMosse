import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'historial_reservas.dart';
import 'paso_de_trazabilidad.dart';
import '../comun/fechas.dart';
import '../comun/marco_de_tarjeta.dart';

class Trazabilidad extends StatelessWidget {
  const Trazabilidad({super.key, required this.reserva});

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
    return MarcoDeTarjeta(
      recorte: Clip.none,
      padding: const EdgeInsets.all(Medidas.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRAZABILIDAD',
            style: Textos.sobretitulo.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: Medidas.s16),
          PasoDeTrazabilidad(
            icono: Icons.check_circle_outline_rounded,
            color: p.stateSuccessInk,
            titulo: 'Reserva creada',
            subtitulo: 'Por ${r.usuario} · ${_fechaHora(r.creadoEn)}',
          ),
          if (segunda != null) ...[
            const SizedBox(height: Medidas.s12),
            PasoDeTrazabilidad(
              icono: segunda.$2,
              color: segunda.$3,
              titulo: segunda.$1,
              subtitulo: segunda.$4,
            ),
          ],
          if (aviso != null) ...[
            const SizedBox(height: Medidas.s12),
            PasoDeTrazabilidad(
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

String _fechaHora(DateTime d) => '${fechaLegible(d)} ${horaCorta(d)}';
