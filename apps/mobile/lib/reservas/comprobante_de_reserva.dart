import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../comun/marco_de_tarjeta.dart';
import '../comun/troquel.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fila_de_dato.dart';
import 'fila_de_total.dart';
import 'reservas.dart';

/// El aviso de la hora y el troquel con espacio, fecha, horario y total de la reserva.
class ComprobanteDeReserva extends StatelessWidget {
  const ComprobanteDeReserva({super.key, required this.reserva});

  final Reserva reserva;

  String get _horario {
    final r = reserva;
    final horas = r.fin.difference(r.inicio).inHours;
    return '${rangoDeHoras(r.inicio, r.fin)} · ${duracion(horas)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Te esperamos. Te vamos a avisar una hora antes.',
            textAlign: TextAlign.center,
            style: Textos.cuerpo.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: Medidas.s24),
          MarcoDeTarjeta(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(Medidas.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilaDeDato(
                        dato: 'Espacio',
                        valor: r.espacio,
                        codigo: true,
                      ),
                      FilaDeDato(dato: 'Fecha', valor: fechaLarga(r.inicio)),
                      FilaDeDato(dato: 'Horario', valor: _horario),
                    ],
                  ),
                ),
                Troquel(fondo: p.bgBase),
                Padding(
                  padding: const EdgeInsets.all(Medidas.s16),
                  child: FilaDeTotal(total: r.total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
