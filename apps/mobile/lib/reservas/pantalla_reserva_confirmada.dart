import 'package:flutter/material.dart';

import '../comun/movimiento.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'barra_de_salida_de_reserva.dart';
import 'comprobante_de_reserva.dart';
import 'fondo_de_foto_de_reserva.dart';
import 'pasos_de_reserva.dart';
import 'reservas.dart';

/// El comprobante: la reserva quedó hecha. Espera a que la persona elija adónde ir.
class PantallaReservaConfirmada extends StatelessWidget {
  const PantallaReservaConfirmada({super.key, required this.reserva});

  final Reserva reserva;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: const BarraDeSalidaDeReserva(),
      body: Stack(
        children: [
          FondoDeFotoDeReserva(deporte: reserva.deporte),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Medidas.s24,
                Medidas.s40,
                Medidas.s24,
                Medidas.s40,
              ),
              children: [
                const PasosDeReserva(actual: 2),
                const SizedBox(height: Medidas.s24),
                Festejo(
                  centro: PulsoDeExito(
                    icono: Icons.check_circle_outline_rounded,
                    fondo: p.stateSuccessMuted,
                    tinta: p.stateSuccessInk,
                  ),
                  grito: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '¡A LA CANCHA!',
                            style: Textos.display.copyWith(
                              fontSize: 36,
                              color: p.accentBase,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: Medidas.s8),
                      Semantics(
                        header: true,
                        liveRegion: true,
                        child: Text(
                          '¡Reserva confirmada!',
                          textAlign: TextAlign.center,
                          style: Textos.h1.copyWith(color: p.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  comprobante: ComprobanteDeReserva(reserva: reserva),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
