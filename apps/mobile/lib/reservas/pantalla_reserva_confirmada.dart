import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../comun/marco_de_tarjeta.dart';
import '../comun/movimiento.dart';
import '../comun/troquel.dart';
import '../sedes/fotos.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fechas.dart';
import 'pantalla_confirmar_reserva.dart';
import 'reservas.dart';

/// El comprobante: la reserva quedó hecha. Espera a que la persona elija adónde ir.
class PantallaReservaConfirmada extends StatelessWidget {
  const PantallaReservaConfirmada({super.key, required this.reserva});

  final Reserva reserva;

  String get _horario {
    String dos(int n) => n.toString().padLeft(2, '0');
    final r = reserva;
    final horas = r.fin.difference(r.inicio).inHours;
    return '${dos(r.inicio.hour)}:${dos(r.inicio.minute)} – '
        '${dos(r.fin.hour)}:${dos(r.fin.minute)} · ${duracion(horas)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final r = reserva;
    return Scaffold(
      backgroundColor: p.bgBase,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Medidas.s24,
            Medidas.s8,
            Medidas.s24,
            Medidas.s16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotonPrimario(
                texto: 'VER MIS RESERVAS',
                alTocar: () => context.go('/reservas'),
              ),
              const SizedBox(height: Medidas.s8),
              Center(
                child: BotonTexto(
                  texto: 'Volver al inicio',
                  alTocar: () => context.go('/inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 440,
            child: Stack(
              fit: StackFit.expand,
              children: [
                FotoConVelo(
                  imagen: fotoDeDeporte(r.deporte),
                  child: const SizedBox.expand(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.6, 1],
                      colors: [p.bgBase.withValues(alpha: 0), p.bgBase],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                  comprobante: SizedBox(
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    FilaDeDato(
                                      dato: 'Espacio',
                                      valor: r.espacio,
                                      codigo: true,
                                    ),
                                    FilaDeDato(
                                      dato: 'Fecha',
                                      valor: fechaLarga(r.inicio),
                                    ),
                                    FilaDeDato(
                                      dato: 'Horario',
                                      valor: _horario,
                                    ),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
