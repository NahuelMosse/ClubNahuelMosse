import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../tema/tokens.dart';

/// LIMPIAR y APLICAR al pie del panel de filtros; [alAplicar] en `null` deshabilita APLICAR.
class AccionesDeFiltros extends StatelessWidget {
  const AccionesDeFiltros({
    super.key,
    required this.alLimpiar,
    required this.alAplicar,
  });

  final VoidCallback alLimpiar;
  final VoidCallback? alAplicar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s24,
        0,
        Medidas.s24,
        Medidas.s24,
      ),
      child: Row(
        children: [
          Expanded(
            child: BotonContorno(texto: 'LIMPIAR', alTocar: alLimpiar),
          ),
          const SizedBox(width: Medidas.s12),
          Expanded(
            child: BotonPrimario(texto: 'APLICAR', alTocar: alAplicar),
          ),
        ],
      ),
    );
  }
}
