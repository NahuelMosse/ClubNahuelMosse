import 'package:flutter/material.dart';
import '../comun/barra_fija.dart';
import '../comun/boton.dart';
import '../tema/tokens.dart';

class BarraDeBusqueda extends StatelessWidget {
  const BarraDeBusqueda({
    super.key,
    required this.alLimpiar,
    required this.alConsultar,
    required this.consultando,
  });

  final VoidCallback? alLimpiar;
  final VoidCallback? alConsultar;
  final bool consultando;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return BarraFija(
      color: p.bgSurface,
      child: Row(
        children: [
          BotonTexto(texto: 'LIMPIAR', alTocar: alLimpiar),
          const SizedBox(width: Medidas.s12),
          Expanded(
            child: BotonPrimario(
              texto: 'CONSULTAR',
              alTocar: alConsultar,
              cargando: consultando,
            ),
          ),
        ],
      ),
    );
  }
}
