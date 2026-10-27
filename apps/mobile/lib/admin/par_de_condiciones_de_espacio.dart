import 'package:flutter/material.dart';

import '../comun/selector.dart';
import 'par_de_campos.dart';

/// Condición (techada o al aire libre) e iluminación de un espacio, lado a lado. Un
/// callback en `null` deshabilita su selector.
class ParDeCondicionesDeEspacio extends StatelessWidget {
  const ParDeCondicionesDeEspacio({
    super.key,
    required this.techada,
    required this.iluminada,
    required this.alElegirCondicion,
    required this.alElegirIluminacion,
  });

  final bool techada;
  final bool iluminada;
  final VoidCallback? alElegirCondicion;
  final VoidCallback? alElegirIluminacion;

  @override
  Widget build(BuildContext context) {
    return ParDeCampos(
      izquierda: CampoSelector(
        etiqueta: 'CONDICIÓN',
        etiquetaAccesible: 'Condición',
        valor: techada ? 'Techada' : 'Al aire libre',
        placeholder: '',
        icono: Icons.expand_more_rounded,
        alTocar: alElegirCondicion,
      ),
      derecha: CampoSelector(
        etiqueta: 'ILUMINACIÓN',
        etiquetaAccesible: 'Iluminación',
        valor: iluminada ? 'Iluminada' : 'Sin iluminación',
        placeholder: '',
        icono: Icons.expand_more_rounded,
        alTocar: alElegirIluminacion,
      ),
    );
  }
}
