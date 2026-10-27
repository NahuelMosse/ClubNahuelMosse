import 'package:flutter/material.dart';

import '../comun/boton.dart';
import '../comun/campo_texto.dart';
import '../tema/tokens.dart';

/// El campo de búsqueda del historial y el botón que abre los filtros.
class BuscadorDeReservas extends StatelessWidget {
  const BuscadorDeReservas({
    super.key,
    required this.controlador,
    required this.alAbrirFiltros,
  });

  final TextEditingController controlador;
  final VoidCallback alAbrirFiltros;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CampoTexto(
            etiquetaAccesible: 'Buscar reserva',
            // Con el botón Filtros al lado, en 360 «Buscar reserva» no entra entero.
            placeholder: MediaQuery.sizeOf(context).width < 400
                ? 'Buscar'
                : 'Buscar reserva',
            controlador: controlador,
            accionFinal: Icon(Icons.search_rounded, color: p.textMuted),
          ),
        ),
        const SizedBox(width: Medidas.s8),
        Flexible(
          child: BotonContorno(
            texto: 'Filtros',
            icono: Icons.tune_rounded,
            compacto: true,
            expandir: false,
            alTocar: alAbrirFiltros,
          ),
        ),
      ],
    );
  }
}
