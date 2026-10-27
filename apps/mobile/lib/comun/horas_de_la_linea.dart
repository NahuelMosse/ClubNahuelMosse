import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';
import 'fechas.dart';

/// Las horas escritas debajo de la [LineaDelDia], una de cada cuatro celdas.
class HorasDeLaLinea extends StatelessWidget {
  const HorasDeLaLinea({
    super.key,
    required this.cantidad,
    required this.desde,
  });

  final int cantidad;
  final int desde;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final marca = Textos.mono.copyWith(fontSize: 11, color: p.textPrimary);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < cantidad; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: i % 4 == 0
                    ? Text(
                        dosCifras(desde + i),
                        style: marca,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
