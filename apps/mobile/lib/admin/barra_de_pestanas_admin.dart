import 'package:flutter/material.dart';
import '../comun/chip_elegible.dart';
import '../reservas/reservas.dart' show EstadoDeReserva;
import '../tema/tokens.dart';
import 'historial_reservas.dart';

class BarraDePestanasAdmin extends StatelessWidget {
  const BarraDePestanasAdmin({
    super.key,
    required this.elegido,
    required this.contadores,
    required this.alElegir,
  });

  final EstadoDeReserva? elegido;
  final Contadores? contadores;
  final ValueChanged<EstadoDeReserva?> alElegir;

  @override
  Widget build(BuildContext context) {
    final c = contadores;
    Widget pestana(String texto, EstadoDeReserva? valor, int? cuenta) {
      final activa = elegido == valor;
      final etiqueta = cuenta == null ? texto : '$texto ($cuenta)';
      final p = context.paleta;
      return Padding(
        padding: const EdgeInsets.only(right: Medidas.s8),
        child: ChipElegible(
          texto: etiqueta,
          elegido: activa,
          alTocar: () => alElegir(valor),
          relleno: const EdgeInsets.symmetric(
            horizontal: Medidas.s16,
            vertical: Medidas.s12,
          ),
          tintaApagada: p.textSecondary,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          pestana('Todas', null, c?.todas),
          pestana('Activas', EstadoDeReserva.activa, c?.activas),
          pestana('Completadas', EstadoDeReserva.completada, c?.completadas),
          pestana('Anuladas', EstadoDeReserva.anulada, c?.anuladas),
        ],
      ),
    );
  }
}
