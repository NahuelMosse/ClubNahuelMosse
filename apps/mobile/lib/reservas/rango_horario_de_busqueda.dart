import 'package:flutter/material.dart';

import '../comun/selector.dart';
import '../tema/tokens.dart';
import 'reglas_busqueda.dart';

/// Los selectores DESDE y HASTA del formulario de consulta de canchas.
class RangoHorarioDeBusqueda extends StatelessWidget {
  const RangoHorarioDeBusqueda({
    super.key,
    required this.desde,
    required this.hasta,
    required this.errorDesde,
    required this.errorHasta,
    required this.alElegirDesde,
    required this.alElegirHasta,
  });

  final int desde;
  final int hasta;
  final String? errorDesde;
  final String? errorHasta;
  final VoidCallback? alElegirDesde;
  final VoidCallback? alElegirHasta;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoSelector(
            etiqueta: 'DESDE',
            etiquetaAccesible: 'Desde',
            valor: hhmm(desde),
            placeholder: '',
            icono: Icons.expand_more_rounded,
            alTocar: alElegirDesde,
            error: errorDesde,
          ),
        ),
        const SizedBox(width: Medidas.s12),
        Expanded(
          child: CampoSelector(
            etiqueta: 'HASTA',
            etiquetaAccesible: 'Hasta',
            valor: hhmm(hasta),
            placeholder: '',
            icono: Icons.expand_more_rounded,
            alTocar: alElegirHasta,
            error: errorHasta,
          ),
        ),
      ],
    );
  }
}
