import 'package:flutter/material.dart';
import '../comun/chip_elegible.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Una fila de chips para elegir una opción: la elegida en lima. [prefijo] va en la
/// etiqueta accesible de cada chip («Deporte Fútbol»), porque el mismo nombre aparece en
/// la portada y en las tarjetas.
class FiltroDeCanchas extends StatelessWidget {
  const FiltroDeCanchas({
    super.key,
    required this.titulo,
    required this.opciones,
    required this.elegida,
    required this.habilitado,
    required this.prefijo,
    required this.alElegir,
  });

  final String titulo;
  final List<(String?, String, IconData?)> opciones;
  final String? elegida;
  final bool habilitado;
  final String prefijo;
  final ValueChanged<String?> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            titulo,
            style: Textos.sobretitulo.copyWith(color: p.textMuted),
          ),
        ),
        const SizedBox(height: Medidas.s8),
        Wrap(
          spacing: Medidas.s8,
          runSpacing: Medidas.s8,
          children: [
            for (final (clave, texto, icono) in opciones)
              ChipElegible(
                texto: texto,
                icono: icono,
                etiqueta: '$prefijo $texto',
                elegido: clave == elegida,
                alTocar: habilitado ? () => alElegir(clave) : null,
                alto: Medidas.tactil + 4,
                conBorde: true,
              ),
          ],
        ),
      ],
    );
  }
}
