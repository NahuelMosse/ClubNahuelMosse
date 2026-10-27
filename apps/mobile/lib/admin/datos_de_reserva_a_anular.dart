import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../comun/formato_precio.dart';
import '../tema/tokens.dart';
import 'dato_de_anulacion.dart';
import 'historial_reservas.dart';

/// La tabla con los datos de la reserva que se va a anular.
class DatosDeReservaAAnular extends StatelessWidget {
  const DatosDeReservaAAnular({
    super.key,
    required this.reserva,
    required this.horario,
  });

  final ReservaHistorial reserva;
  final String horario;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Container(
      padding: const EdgeInsets.all(Medidas.s16),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
      ),
      child: Column(
        children: [
          DatoDeAnulacion('Usuario', r.usuario),
          DatoDeAnulacion('Sede', r.sede),
          DatoDeAnulacion('Cancha', r.espacio, tecnico: true),
          DatoDeAnulacion('Cuándo', '${fechaLarga(r.inicio)}\n$horario'),
          DatoDeAnulacion('Importe', pesos(r.total)),
        ],
      ),
    );
  }
}
