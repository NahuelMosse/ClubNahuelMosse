import 'package:flutter/material.dart';

import '../../spaces/domain/space.dart';
import 'availability_space_card.dart';
import 'paired_grid.dart';
import 'slots_section.dart';

/// SELECCIONÁ CANCHA: las canchas del mismo tipo, con la elegida marcada.
class SpaceSelection extends StatelessWidget {
  const SpaceSelection({
    super.key,
    required this.canchas,
    required this.elegida,
    required this.alElegir,
  });

  final List<Space> canchas;
  final String elegida;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return SlotsSection(
      titulo: 'SELECCIONÁ CANCHA',
      child: PairedGrid(
        hijos: [
          for (final c in canchas)
            AvailabilitySpaceCard(
              cancha: c,
              elegida: c.id == elegida,
              alTocar: () => alElegir(c.id),
            ),
        ],
      ),
    );
  }
}
