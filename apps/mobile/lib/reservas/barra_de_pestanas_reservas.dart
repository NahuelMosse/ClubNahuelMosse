import 'package:flutter/material.dart';
import '../comun/chip_elegible.dart';
import '../tema/tokens.dart';

/// `Segmented-Tab`: Próximas o Historial.
class BarraDePestanasReservas extends StatelessWidget {
  const BarraDePestanasReservas({
    super.key,
    required this.historial,
    required this.alElegir,
  });

  final bool historial;
  final ValueChanged<bool> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    Widget pestana(String texto, {required bool esHistorial}) {
      final elegida = historial == esHistorial;
      return Expanded(
        child: ChipElegible(
          texto: texto,
          elegido: elegida,
          alTocar: () => alElegir(esHistorial),
          alto: Medidas.s48,
          relleno: EdgeInsets.zero,
          fondoApagado: Colors.transparent,
          tintaApagada: p.textSecondary,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Medidas.s4),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Row(
        children: [
          pestana('Próximas', esHistorial: false),
          const SizedBox(width: Medidas.s4),
          pestana('Historial', esHistorial: true),
        ],
      ),
    );
  }
}
