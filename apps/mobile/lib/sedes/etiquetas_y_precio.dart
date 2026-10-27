import 'package:flutter/material.dart';
import '../comun/etiqueta.dart';
import '../espacios/espacio.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Condición e iluminación a la izquierda y el precio a la derecha; con el texto grande el
/// precio baja debajo de las etiquetas en vez de cortarse.
class EtiquetasYPrecio extends StatelessWidget {
  const EtiquetasYPrecio({
    super.key,
    required this.cancha,
    required this.precio,
  });

  final Espacio cancha;
  final String precio;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final etiquetas = Wrap(
      spacing: Medidas.s4,
      runSpacing: Medidas.s4,
      children: [
        Etiqueta(
          texto: cancha.condicion,
          icono: cancha.techada
              ? Icons.roofing_rounded
              : Icons.wb_sunny_outlined,
        ),
        Etiqueta(
          texto: cancha.iluminacion,
          icono: cancha.iluminada
              ? Icons.lightbulb_outline_rounded
              : Icons.nightlight_outlined,
        ),
      ],
    );
    final monto = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(precio, style: Textos.h2.copyWith(color: p.accentInk)),
        Text('/ HORA', style: Textos.sobretitulo.copyWith(color: p.textMuted)),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          etiquetas,
          const SizedBox(height: Medidas.s8),
          Align(alignment: Alignment.centerRight, child: monto),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: etiquetas),
        const SizedBox(width: Medidas.s8),
        monto,
      ],
    );
  }
}
