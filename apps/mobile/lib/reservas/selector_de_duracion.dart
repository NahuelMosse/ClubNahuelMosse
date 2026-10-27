import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'boton_redondo.dart';
import 'reglas_busqueda.dart';

/// `Stepper-Duracion`: una hora menos, la duración y una hora más.
class SelectorDeDuracion extends StatelessWidget {
  const SelectorDeDuracion({
    super.key,
    required this.horas,
    required this.alCambiar,
  });

  final int horas;
  final ValueChanged<int> alCambiar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      height: Medidas.altoControl,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.bgSurfaceRaised,
        borderRadius: BorderRadius.circular(Medidas.radioPill),
      ),
      child: Row(
        children: [
          BotonRedondo(
            icono: Icons.remove_rounded,
            etiqueta: 'Una hora menos',
            alTocar: horas > minHoras ? () => alCambiar(horas - 1) : null,
          ),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text(
                duracion(horas),
                textAlign: TextAlign.center,
                style: Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
              ),
            ),
          ),
          BotonRedondo(
            icono: Icons.add_rounded,
            etiqueta: 'Una hora más',
            alTocar: horas < maxHoras ? () => alCambiar(horas + 1) : null,
          ),
        ],
      ),
    );
  }
}
