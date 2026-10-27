import 'package:flutter/material.dart';

import 'aparecer.dart';
import 'tiempos.dart';

/// Hace aparecer a [hijos] uno tras otro: el primero a los [inicio] y cada siguiente [paso]
/// después del anterior.
class EntradaEscalonada extends StatelessWidget {
  const EntradaEscalonada({
    super.key,
    required this.hijos,
    this.inicio = Duration.zero,
    this.paso = Movimiento.paso,
    this.duracion = Movimiento.entrada,
    this.desdeY = 20,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> hijos;
  final Duration inicio;
  final Duration paso;
  final Duration duracion;
  final double desdeY;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: crossAxisAlignment,
    children: [
      for (var i = 0; i < hijos.length; i++)
        Aparecer(
          retraso: inicio + paso * i,
          duracion: duracion,
          desdeY: desdeY,
          child: hijos[i],
        ),
    ],
  );
}
