import 'package:flutter/material.dart';
import '../espacios/espacio.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'marco_elegible.dart';

class TarjetaCanchaDeHorarios extends StatelessWidget {
  const TarjetaCanchaDeHorarios({
    super.key,
    required this.cancha,
    required this.elegida,
    required this.alTocar,
  });

  final Espacio cancha;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return MarcoElegible(
      etiqueta: 'Cancha ${cancha.numero}, ${cancha.condicion}',
      elegido: elegida,
      alTocar: alTocar,
      child: Padding(
        padding: const EdgeInsets.all(Medidas.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancha ${cancha.numero}',
              style: Textos.cuerpoFuerte.copyWith(
                color: elegida ? p.accentOn : p.textPrimary,
              ),
            ),
            const SizedBox(height: Medidas.s4),
            Text(
              cancha.condicion,
              style: Textos.leyenda.copyWith(
                color: elegida ? p.accentOn : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
