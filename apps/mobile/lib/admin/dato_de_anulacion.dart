import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Una fila «etiqueta — valor» de la tabla de datos de la reserva.
class DatoDeAnulacion extends StatelessWidget {
  const DatoDeAnulacion(
    this.etiqueta,
    this.valor, {
    super.key,
    this.tecnico = false,
  });

  final String etiqueta;
  final String valor;

  /// El valor es el nombre técnico del espacio.
  final bool tecnico;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$etiqueta, $valor',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Medidas.s4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              etiqueta,
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
            const SizedBox(width: Medidas.s12),
            Expanded(
              child: Text(
                valor,
                textAlign: TextAlign.end,
                style: tecnico
                    ? Textos.mono.copyWith(color: p.textPrimary)
                    : Textos.cuerpoFuerte.copyWith(color: p.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
