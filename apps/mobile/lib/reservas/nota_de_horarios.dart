import 'package:flutter/material.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// `Nota-Ocupados`: cuántos inicios de la grilla no se pueden elegir.
class NotaDeHorarios extends StatelessWidget {
  const NotaDeHorarios({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Container(
      padding: const EdgeInsets.all(Medidas.s12),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(Medidas.radioMd),
        border: Border.all(color: p.borderDefault),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: p.textSecondary),
          const SizedBox(width: Medidas.s8),
          Expanded(
            child: Text(
              texto,
              style: Textos.leyenda.copyWith(color: p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
