import 'package:flutter/material.dart';
import '../comun/formato_precio.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// TOTAL y el monto en lima.
class FilaDeTotal extends StatelessWidget {
  const FilaDeTotal({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Medidas.s8,
      children: [
        Text('TOTAL', style: Textos.sobretitulo.copyWith(color: p.textMuted)),
        Text(pesos(total), style: Textos.h1.copyWith(color: p.accentInk)),
      ],
    );
  }
}
