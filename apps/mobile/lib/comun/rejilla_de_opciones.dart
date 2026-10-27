// kit-shape: la rejilla y su opción privada se leen juntas y no se usan por separado
import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Las opciones de [elegirOpcion] en [columnas] columnas, con la [elegida] marcada.
///
/// Todas se construyen de una: son pocas y así se llega a cualquiera sin que la lista las
/// vaya descartando.
class RejillaDeOpciones<T> extends StatelessWidget {
  const RejillaDeOpciones({
    super.key,
    required this.opciones,
    required this.columnas,
    required this.alElegir,
    this.elegida,
  });

  final List<(T, String)> opciones;
  final int columnas;
  final ValueChanged<T> alElegir;
  final T? elegida;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Medidas.s12,
        0,
        Medidas.s12,
        Medidas.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < opciones.length; i += columnas)
            Row(
              children: [
                for (var j = i; j < i + columnas; j++)
                  Expanded(
                    child: j < opciones.length
                        ? _Opcion(
                            texto: opciones[j].$2,
                            elegida: opciones[j].$1 == elegida,
                            centrada: columnas > 1,
                            alTocar: () => alElegir(opciones[j].$1),
                          )
                        : const SizedBox.shrink(),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.texto,
    required this.elegida,
    required this.centrada,
    required this.alTocar,
  });

  final String texto;
  final bool elegida;
  final bool centrada;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Semantics(
      button: true,
      selected: elegida,
      child: Material(
        color: elegida ? p.accentMuted : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Medidas.tactil + 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Medidas.s12),
              child: Row(
                mainAxisAlignment: centrada
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      texto,
                      style: (elegida ? Textos.cuerpoFuerte : Textos.cuerpo)
                          .copyWith(color: p.textPrimary),
                    ),
                  ),
                  if (elegida && !centrada) ...[
                    const Spacer(),
                    Icon(Icons.check_rounded, size: 20, color: p.accentInk),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
