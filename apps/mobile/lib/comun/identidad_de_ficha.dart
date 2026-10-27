import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Las iniciales en su cuadrado de acento, con el nombre y el correo al lado.
class IdentidadDeFicha extends StatelessWidget {
  const IdentidadDeFicha({
    super.key,
    required this.iniciales,
    required this.nombre,
    required this.correo,
  });

  final String iniciales;
  final String nombre;
  final String correo;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      children: [
        Container(
          width: 76,
          height: 76,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.accentBase,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            iniciales,
            style: Textos.display.copyWith(color: p.accentOn),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: Textos.h2.copyWith(
                  letterSpacing: 0,
                  color: p.textOnMedia,
                ),
              ),
              Text(
                correo,
                style: Textos.leyenda.copyWith(color: p.textOnMediaMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
