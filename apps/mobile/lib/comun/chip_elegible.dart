import 'package:flutter/material.dart';

import '../tema/tema.dart';
import '../tema/tokens.dart';

/// Un chip o una pestaña que se elige tocándola: la elegida en lima. Cada
/// `ChipElegible(...)` fija lo que lo distingue: [alto] mínimo, [relleno], [fondoApagado],
/// [conBorde], [estilo], [icono] y las tintas de la letra sin elegir.
///
/// Se anuncia como botón, seleccionado y habilitado según [alTocar]. Sin [alTocar] queda
/// deshabilitado; con [tintaSinTocar] además apaga la letra.
class ChipElegible extends StatelessWidget {
  const ChipElegible({
    super.key,
    required this.texto,
    required this.elegido,
    required this.alTocar,
    this.etiqueta,
    this.icono,
    this.estilo = Textos.cuerpoFuerte,
    this.alto = 0,
    this.relleno = const EdgeInsets.symmetric(horizontal: Medidas.s16),
    this.fondoApagado,
    this.conBorde = false,
    this.tintaApagada,
    this.tintaSinTocar,
  });

  final String texto;
  final bool elegido;
  final VoidCallback? alTocar;

  /// Lo que lee el lector de pantalla; sin ella, [texto].
  final String? etiqueta;
  final IconData? icono;
  final TextStyle estilo;

  /// El alto mínimo; con alto el contenido queda centrado.
  final double alto;
  final EdgeInsetsGeometry relleno;

  /// Sin ellos: `bgSurfaceRaised` y `textPrimary`.
  final Color? fondoApagado;
  final Color? tintaApagada;

  /// La letra cuando [alTocar] es nulo y el chip no está elegido.
  final Color? tintaSinTocar;

  /// El borde de la forma, lima oscuro si está elegido.
  final bool conBorde;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final tinta = elegido
        ? p.accentOn
        : alTocar == null && tintaSinTocar != null
        ? tintaSinTocar!
        : tintaApagada ?? p.textPrimary;
    final simbolo = icono;
    final letra = Text(texto, style: estilo.copyWith(color: tinta));
    final contenido = simbolo == null
        ? letra
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(simbolo, size: 18, color: tinta),
              const SizedBox(width: Medidas.s8),
              letra,
            ],
          );
    return Semantics(
      container: true,
      button: true,
      selected: elegido,
      enabled: alTocar != null,
      label: etiqueta ?? texto,
      excludeSemantics: true,
      onTap: alTocar,
      child: Material(
        color: elegido ? p.accentBase : fondoApagado ?? p.bgSurfaceRaised,
        shape: conBorde
            ? StadiumBorder(
                side: BorderSide(
                  color: elegido ? p.accentEdge : p.borderControl,
                ),
              )
            : const StadiumBorder(),
        child: InkWell(
          onTap: alTocar,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: alto),
            child: Padding(
              padding: relleno,
              child: alto > 0
                  ? Center(widthFactor: 1, child: contenido)
                  : contenido,
            ),
          ),
        ),
      ),
    );
  }
}
