import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../comun/tarjeta_reserva.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'historial_reservas.dart';

/// Sede, usuario, espacio, fecha y horario de una reserva del admin.
class DetalleDeReserva extends StatelessWidget {
  const DetalleDeReserva({
    super.key,
    required this.reserva,
    required this.horario,
    required this.huecoAntesDeLaSede,
    this.separacionFechaYHorario = Medidas.s8,
  });

  final ReservaHistorial reserva;
  final String horario;
  final double huecoAntesDeLaSede;
  final double separacionFechaYHorario;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: huecoAntesDeLaSede),
        Text(
          '${r.sede} · ${r.direccion}',
          style: Textos.leyenda.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: Medidas.s12),
        UsuarioDeReserva(usuario: r.usuario),
        const SizedBox(height: Medidas.s8),
        Text(r.espacio, style: Textos.mono.copyWith(color: p.textMuted)),
        const SizedBox(height: Medidas.s8),
        FechaYHorario(
          fecha: fechaLarga(r.inicio),
          horario: horario,
          separacionVertical: separacionFechaYHorario,
          alineacion: WrapCrossAlignment.start,
        ),
      ],
    );
  }
}
