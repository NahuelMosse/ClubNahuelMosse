import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Los tres pasos de la reserva, con [actual] contado desde cero.
class PasosDeReserva extends StatelessWidget {
  const PasosDeReserva({super.key, required this.actual});

  final int actual;

  static const _nombres = ['Elegí cancha', 'Confirmás', '¡Listo!'];

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      label: 'Paso ${actual + 1} de ${_nombres.length}: ${_nombres[actual]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _nombres.length; i++) ...[
            if (i > 0) const SizedBox(width: Medidas.s8),
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= actual ? p.accentBase : p.bgSurfaceRaised,
                      borderRadius: BorderRadius.circular(Medidas.radioPill),
                    ),
                  ),
                  const SizedBox(height: Medidas.s8),
                  Text(
                    _nombres[i],
                    textAlign: TextAlign.center,
                    style: Textos.leyenda.copyWith(
                      color: i == actual ? p.textPrimary : p.textMuted,
                      fontWeight: i == actual ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
