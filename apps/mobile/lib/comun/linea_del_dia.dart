import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Estado de una hora en la [LineaDelDia].
enum EstadoFranja { libre, ocupada, elegida }

/// Tira de celdas, una por hora, con el estado de cada franja del día.
class LineaDelDia extends StatelessWidget {
  const LineaDelDia({super.key, required this.franjas, this.desde = 8});

  final List<EstadoFranja> franjas;
  final int desde;

  static String _hora(int h) => h.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final marca = Textos.mono.copyWith(fontSize: 11, color: p.textMuted);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TU DÍA EN LA CANCHA',
                style: Textos.sobretitulo.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.88,
                  color: p.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  children: [
                    _Leyenda(color: p.accentMuted, texto: 'Libre'),
                    _Leyenda(color: p.stateDisabled, texto: 'Ocupado'),
                    _Leyenda(color: p.accentBase, texto: 'Elegido'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < franjas.length; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey('franja-${_hora(desde + i)}'),
                    child: Semantics(
                      label: '${_hora(desde + i)} h ${franjas[i].name}',
                      child: ExcludeSemantics(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: switch (franjas[i]) {
                                EstadoFranja.libre => p.accentMuted,
                                EstadoFranja.ocupada => p.stateDisabled,
                                EstadoFranja.elegida => p.accentBase,
                              },
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < franjas.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: i % 4 == 0
                          ? Text(
                              _hora(desde + i),
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
          ),
        ],
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: const SizedBox(width: 8, height: 8),
        ),
        const SizedBox(width: 4),
        Text(
          texto,
          style: Textos.leyenda.copyWith(
            fontSize: 11,
            height: 14 / 11,
            color: p.textMuted,
          ),
        ),
      ],
    );
  }
}
