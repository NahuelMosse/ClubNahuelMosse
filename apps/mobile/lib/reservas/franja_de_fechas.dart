import 'package:flutter/material.dart';

import '../comun/fechas.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'marco_elegible.dart';
import 'reglas_busqueda.dart';

/// Los próximos siete días desde hoy, en una fila que se desliza.
class FranjaDeFechas extends StatelessWidget {
  const FranjaDeFechas({
    super.key,
    required this.hoy,
    required this.elegida,
    required this.alElegir,
  });

  final DateTime hoy;
  final DateTime? elegida;
  final ValueChanged<DateTime> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < diasALaVista; i++) ...[
            if (i > 0) const SizedBox(width: Medidas.s8),
            Builder(
              builder: (context) {
                final dia = DateTime.utc(hoy.year, hoy.month, hoy.day + i);
                final esta = dia == elegida;
                final tinta = esta ? p.accentOn : p.textPrimary;
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 56,
                    minHeight: 64,
                  ),
                  child: MarcoElegible(
                    etiqueta: '${diaDeLaSemana(dia)} ${dia.day}',
                    elegido: esta,
                    alTocar: () => alElegir(dia),
                    child: Padding(
                      padding: const EdgeInsets.all(Medidas.s8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            diaAbreviado(dia),
                            style: Textos.sobretitulo.copyWith(
                              color: esta ? p.accentOn : p.textMuted,
                            ),
                          ),
                          Text(
                            '${dia.day}',
                            style: Textos.h2.copyWith(color: tinta),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
