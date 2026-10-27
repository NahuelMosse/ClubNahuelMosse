import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../comun/tarjeta_reserva.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'reservas.dart';
import 'tarjeta_reserva.dart';

/// Lo de abajo de la tarjeta: la cuenta regresiva, el espacio, la fecha y el horario, con
/// el porqué si la reserva se canceló o se anuló.
class DetalleDeReserva extends StatelessWidget {
  const DetalleDeReserva({
    super.key,
    required this.reserva,
    required this.cuenta,
    required this.porque,
  });

  final Reserva reserva;
  final String? cuenta;
  final String? porque;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    final cuenta = this.cuenta;
    final porque = this.porque;
    final anulada = r.estado == EstadoDeReserva.anulada;
    return Padding(
      padding: const EdgeInsets.all(Medidas.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cuenta != null) ...[
            Text(
              cuenta,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 11 * 0.08,
                color: p.accentInk,
              ),
            ),
            const SizedBox(height: Medidas.s4),
          ],
          Text(r.espacio, style: Textos.mono.copyWith(color: p.textMuted)),
          const SizedBox(height: Medidas.s8),
          FechaYHorario(fecha: fechaLarga(r.inicio), horario: horarioDe(r)),
          if (porque != null) ...[
            const SizedBox(height: Medidas.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: anulada ? p.stateDangerInk : p.textSecondary,
                ),
                const SizedBox(width: Medidas.s8),
                Expanded(
                  child: Text(
                    porque,
                    style: Textos.leyenda.copyWith(
                      color: anulada ? p.stateDangerInk : p.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
