import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/tarjeta_reserva.dart';
import '../espacios/iconos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'estado_reserva_chip.dart';
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

  // Con cualquier agrandado del texto, precio y estado ya no entran junto al nombre en 360.
  bool _grande(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(10) > 13;

  Widget _precioYEstado(Paleta p) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        pesos(reserva.total),
        style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
      ),
      const SizedBox(height: Medidas.s4),
      EstadoReservaChip(estado: reserva.estado),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Padding(
      padding: const EdgeInsets.all(Medidas.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(iconoDeDeporte(r.deporte), size: 20, color: p.textSecondary),
              const SizedBox(width: Medidas.s8),
              Expanded(
                child: Text(
                  nombreDeporte,
                  style: Textos.titulo.copyWith(color: p.textPrimary),
                ),
              ),
              // Con el texto muy agrandado, precio y estado bajan debajo del
              // nombre en vez de disputarle el ancho.
              if (!_grande(context)) ...[
                const SizedBox(width: Medidas.s8),
                _precioYEstado(p),
              ],
            ],
          ),
          if (_grande(context)) ...[
            const SizedBox(height: Medidas.s8),
            _precioYEstado(p),
          ],
          const SizedBox(height: Medidas.s4),
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
            separacionVertical: Medidas.s4,
            alineacion: WrapCrossAlignment.start,
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
