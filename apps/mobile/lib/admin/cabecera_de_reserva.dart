import 'package:flutter/material.dart';

import '../comun/formato_precio.dart';
import '../espacios/iconos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'estado_reserva_chip.dart';
import 'historial_reservas.dart';

/// Deporte, precio y estado de una reserva. Con `apilarSiTextoGrande`, y el texto muy
/// agrandado, precio y estado bajan debajo del nombre en vez de disputarle el ancho.
class CabeceraDeReserva extends StatelessWidget {
  const CabeceraDeReserva({
    super.key,
    required this.reserva,
    required this.nombreDeporte,
    required this.separacionPrecioEstado,
    this.huecoAntesDelPrecio = 0,
    this.apilarSiTextoGrande = false,
  });

  final ReservaHistorial reserva;
  final String nombreDeporte;
  final double separacionPrecioEstado;
  final double huecoAntesDelPrecio;
  final bool apilarSiTextoGrande;

  Widget _precioYEstado(Paleta p) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(
        pesos(reserva.total),
        style: Textos.cuerpoFuerte.copyWith(color: p.accentInk),
      ),
      SizedBox(height: separacionPrecioEstado),
      EstadoReservaChip(estado: reserva.estado),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    // Con cualquier agrandado del texto, precio y estado ya no entran junto al nombre en 360.
    final apilar =
        apilarSiTextoGrande && MediaQuery.textScalerOf(context).scale(10) > 13;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              iconoDeDeporte(reserva.deporte),
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
            if (!apilar) ...[
              SizedBox(width: huecoAntesDelPrecio),
              _precioYEstado(p),
            ],
          ],
        ),
        if (apilar) ...[const SizedBox(height: Medidas.s8), _precioYEstado(p)],
      ],
    );
  }
}
