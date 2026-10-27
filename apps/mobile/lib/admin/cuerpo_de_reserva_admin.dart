import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'cabecera_de_reserva.dart';
import 'detalle_de_reserva.dart';
import 'historial_reservas.dart';

/// Lo que cuenta una reserva en el listado del admin: deporte, precio y estado, sede,
/// usuario, espacio, fecha y horario, y el aviso de baja del espacio.
class CuerpoDeReservaAdmin extends StatelessWidget {
  const CuerpoDeReservaAdmin({
    super.key,
    required this.reserva,
    required this.nombreDeporte,
    required this.horario,
  });

  final ReservaHistorial reserva;
  final String nombreDeporte;
  final String horario;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Padding(
      padding: const EdgeInsets.all(Medidas.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabeceraDeReserva(
            reserva: r,
            nombreDeporte: nombreDeporte,
            separacionPrecioEstado: Medidas.s4,
            huecoAntesDelPrecio: Medidas.s8,
            apilarSiTextoGrande: true,
          ),
          DetalleDeReserva(
            reserva: r,
            horario: horario,
            huecoAntesDeLaSede: Medidas.s4,
            separacionFechaYHorario: Medidas.s4,
          ),
          if (r.espacioDeBaja) ...[
            const SizedBox(height: Medidas.s8),
            Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: p.textMuted),
                const SizedBox(width: Medidas.s4),
                Flexible(
                  child: Text(
                    'Baja del espacio deportivo',
                    style: Textos.leyenda.copyWith(color: p.textMuted),
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
