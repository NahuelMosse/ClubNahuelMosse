import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'crece.dart';
import 'horarios.dart';
import 'marco_elegible.dart';

class TarjetaFranja extends StatelessWidget {
  const TarjetaFranja({
    super.key,
    required this.franja,
    required this.elegida,
    required this.alTocar,
    this.actual = false,
  });

  final Franja franja;
  final bool elegida;
  final VoidCallback? alTocar;

  /// Es el horario de la reserva que se modifica.
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tinta = elegida ? p.accentOn : p.textPrimary;
    return Crece(
      activo: elegida,
      child: MarcoElegible(
        etiqueta: actual ? '${franja.texto} (actual)' : franja.texto,
        elegido: elegida,
        alTocar: alTocar,
        atenuado: !franja.disponible,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                franja.texto,
                style: Textos.cuerpoFuerte.copyWith(color: tinta),
              ),
              if (actual)
                Text(
                  '(actual)',
                  style: Textos.leyenda.copyWith(
                    color: elegida ? p.accentOn : p.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
