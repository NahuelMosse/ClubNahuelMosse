import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'reglas_busqueda.dart';
import 'seccion_de_horarios.dart';
import 'selector_de_duracion.dart';

/// DURACIÓN: el selector de horas y lo que se puede elegir en la sede.
class SeccionDeDuracion extends StatelessWidget {
  const SeccionDeDuracion({
    super.key,
    required this.horas,
    required this.cierre,
    required this.alCambiar,
  });

  final int horas;

  /// La hora de cierre de la sede, tal como se muestra.
  final String cierre;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SeccionDeHorarios(
      titulo: 'DURACIÓN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectorDeDuracion(horas: horas, alCambiar: alCambiar),
          const SizedBox(height: Medidas.s8),
          Text(
            'Horas completas, de $minHoras a $maxHoras h. '
            'La sede cierra a las $cierre.',
            style: Textos.leyenda.copyWith(color: p.textSecondary),
          ),
        ],
      ),
    );
  }
}
