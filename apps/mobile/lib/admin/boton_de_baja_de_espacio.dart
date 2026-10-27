import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/en_curso.dart';

/// «Dar de baja el espacio», o el aviso de que la baja está en camino. [alTocar] en `null`
/// deshabilita el botón.
class BotonDeBajaDeEspacio extends StatelessWidget {
  const BotonDeBajaDeEspacio({
    super.key,
    required this.dandoDeBaja,
    required this.alTocar,
  });

  final bool dandoDeBaja;
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    if (dandoDeBaja) return const EnCurso('Dando de baja el espacio');
    return BotonContorno(
      texto: 'DAR DE BAJA EL ESPACIO',
      peligro: true,
      alTocar: alTocar,
    );
  }
}
