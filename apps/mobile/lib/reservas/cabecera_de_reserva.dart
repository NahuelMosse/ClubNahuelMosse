import 'package:flutter/material.dart';

import '../espacios/espacio.dart';
import '../espacios/iconos.dart';
import '../sedes/fotos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'precio_y_estado_de_reserva.dart';
import 'reservas.dart';

/// La foto del deporte, el tipo de cancha con la sede y, si la letra no es grande, el
/// precio y el estado a la derecha.
class CabeceraDeReserva extends StatelessWidget {
  const CabeceraDeReserva({
    super.key,
    required this.reserva,
    required this.catalogo,
    required this.grande,
  });

  final Reserva reserva;
  final Catalogo catalogo;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Padding(
      padding: const EdgeInsets.all(Medidas.s16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Medidas.radioMd),
            child: Image(
              image: fotoDeDeporte(r.deporte),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: Medidas.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      iconoDeDeporte(r.deporte),
                      size: 16,
                      color: p.textSecondary,
                    ),
                    const SizedBox(width: Medidas.s4),
                    Flexible(
                      child: Text(
                        catalogo.tipoCorto(r.deporte, r.tipo),
                        style: Textos.titulo.copyWith(color: p.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Medidas.s4),
                Text(
                  '${r.sede} · ${r.direccion}',
                  style: Textos.leyenda.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
          if (!grande) ...[
            const SizedBox(width: Medidas.s8),
            PrecioYEstadoDeReserva(reserva: r, grande: grande),
          ],
        ],
      ),
    );
  }
}
