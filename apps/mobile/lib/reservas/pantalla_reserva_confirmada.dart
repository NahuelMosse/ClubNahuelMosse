import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../comun/boton.dart';
import '../comun/marco_de_tarjeta.dart';
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
      body: SafeArea(
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
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: p.stateSuccessMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 40,
                  color: p.stateSuccessInk,
                ),
              ),
            ),
            const SizedBox(height: Medidas.s24),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                '¡Reserva confirmada!',
                textAlign: TextAlign.center,
                style: Textos.h1.copyWith(color: p.textPrimary),
              ),
            ),
            const SizedBox(height: Medidas.s12),
            Text(
              'Te esperamos. Te vamos a avisar una hora antes.',
              textAlign: TextAlign.center,
              style: Textos.cuerpo.copyWith(color: p.textSecondary),
            ),
            const SizedBox(height: Medidas.s24),
            MarcoDeTarjeta(
              padding: const EdgeInsets.all(Medidas.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilaDeDato(dato: 'Espacio', valor: r.espacio, codigo: true),
                  FilaDeDato(dato: 'Fecha', valor: fechaLarga(r.inicio)),
                  FilaDeDato(dato: 'Horario', valor: _horario),
                  const SizedBox(height: Medidas.s8),
                  FilaDeTotal(total: r.total),
                ],
              ),
            ),
            const SizedBox(height: Medidas.s24),
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
    );
  }
}
