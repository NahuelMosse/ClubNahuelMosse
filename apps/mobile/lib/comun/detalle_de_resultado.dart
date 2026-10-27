import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El texto de una [PantallaResultado] y, si lo hay, el dato guardado en su recuadro lima.
class DetalleDeResultado extends StatelessWidget {
  const DetalleDeResultado({super.key, required this.texto, this.detalle});

  final String texto;
  final String? detalle;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          texto,
          textAlign: TextAlign.center,
          style: Textos.cuerpo.copyWith(color: p.textSecondary),
        ),
        if (detalle case final dato?) ...[
          const SizedBox(height: Medidas.s16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Medidas.s16,
              vertical: Medidas.s8,
            ),
            decoration: BoxDecoration(
              color: p.bgBase,
              borderRadius: BorderRadius.circular(Medidas.radioMd),
              border: Border.all(color: p.accentInk),
            ),
            child: Text(
              dato,
              textAlign: TextAlign.center,
              // La mono fina en el lima oscuro del modo claro no llega a 4,5:1.
              style: Textos.mono.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? p.accentInk
                    : p.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
