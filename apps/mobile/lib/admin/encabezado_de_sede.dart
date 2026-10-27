import 'package:flutter/material.dart';

import '../sedes/sede.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// El ícono, el nombre, la dirección y la cantidad de canchas de una sede.
class EncabezadoDeSede extends StatelessWidget {
  const EncabezadoDeSede({super.key, required this.sede});

  final Sede sede;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      children: [
        Container(
          width: Medidas.tactil,
          height: Medidas.tactil,
          decoration: BoxDecoration(
            color: p.accentMuted,
            borderRadius: BorderRadius.circular(Medidas.radioMd),
          ),
          child: Icon(Icons.place_outlined, size: 20, color: p.accentInk),
        ),
        const SizedBox(width: Medidas.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sede.nombre,
                style: Textos.titulo.copyWith(color: p.textPrimary),
              ),
              const SizedBox(height: Medidas.s4),
              Text(
                sede.direccion,
                style: Textos.leyenda.copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: Medidas.s12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${sede.canchas}',
              style: Textos.h2.copyWith(color: p.accentInk),
            ),
            Text(
              sede.canchas == 1 ? 'CANCHA' : 'CANCHAS',
              style: Textos.sobretitulo.copyWith(color: p.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
