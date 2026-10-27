import 'package:flutter/material.dart';

import '../espacios/espacio.dart';
import 'grilla_de_a_pares.dart';
import 'seccion_de_horarios.dart';
import 'tarjeta_cancha_de_horarios.dart';

/// SELECCIONÁ CANCHA: las canchas del mismo tipo, con la elegida marcada.
class SeleccionDeCancha extends StatelessWidget {
  const SeleccionDeCancha({
    super.key,
    required this.canchas,
    required this.elegida,
    required this.alElegir,
  });

  final List<Espacio> canchas;
  final String elegida;
  final ValueChanged<String> alElegir;

  @override
  Widget build(BuildContext context) {
    return SeccionDeHorarios(
      titulo: 'SELECCIONÁ CANCHA',
      child: GrillaDeAPares(
        hijos: [
          for (final c in canchas)
            TarjetaCanchaDeHorarios(
              cancha: c,
              elegida: c.id == elegida,
              alTocar: () => alElegir(c.id),
            ),
        ],
      ),
    );
  }
}
