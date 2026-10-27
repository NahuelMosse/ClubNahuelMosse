import 'package:flutter/material.dart';

import '../comun/formato_precio.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'etiqueta_de_estado.dart';
import 'reservas.dart';

/// El total de la reserva y su estado, uno sobre el otro.
class PrecioYEstadoDeReserva extends StatelessWidget {
  const PrecioYEstadoDeReserva({
    super.key,
    required this.reserva,
    required this.grande,
  });

  final Reserva reserva;

  /// Con la letra grande se alinea a la izquierda en vez de a la derecha.
  final bool grande;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: grande
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          pesos(reserva.total),
          style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
        ),
        const SizedBox(height: Medidas.s8),
        EtiquetaDeEstado(estado: reserva.estado),
      ],
    );
  }
}
