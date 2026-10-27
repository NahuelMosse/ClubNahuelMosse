import 'package:flutter/material.dart';
import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../comun/marco_de_tarjeta.dart';
import '../tema/tokens.dart';
import 'cabecera_de_reserva.dart';
import 'detalle_de_reserva.dart';
import 'historial_reservas.dart';

class TarjetaDatosDeReserva extends StatelessWidget {
  const TarjetaDatosDeReserva({
    super.key,
    required this.reserva,
    required this.horario,
    required this.nombreDeporte,
  });

  final ReservaHistorial reserva;
  final String horario;
  final String nombreDeporte;

  @override
  Widget build(BuildContext context) {
    final r = reserva;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '$nombreDeporte, sede ${r.sede}, ${r.direccion}, ${pesos(r.total)}, '
          '${r.estado.name}, usuario ${r.usuario}, ${r.espacio}, '
          '${fechaLarga(r.inicio)}, $horario',
      child: MarcoDeTarjeta(
        recorte: Clip.none,
        padding: const EdgeInsets.all(Medidas.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CabeceraDeReserva(
              reserva: r,
              nombreDeporte: nombreDeporte,
              separacionPrecioEstado: Medidas.s8,
            ),
            DetalleDeReserva(
              reserva: r,
              horario: horario,
              huecoAntesDeLaSede: Medidas.s8,
            ),
          ],
        ),
      ),
    );
  }
}
