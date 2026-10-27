import 'package:flutter/material.dart';

import '../tema/tokens.dart';

/// El marco de un control que se elige, con el estilo de los del prototipo: lima el
/// elegido. El contenido es libre.
class MarcoElegible extends StatelessWidget {
  const MarcoElegible({
    super.key,
    required this.etiqueta,
    required this.elegido,
    required this.alTocar,
    required this.child,
    this.atenuado = false,
  });

  final String etiqueta;
  final bool elegido;
  final VoidCallback? alTocar;
  final Widget child;
  final bool atenuado;

  @override
  Widget build(BuildContext context) {
    final p = context.paleta;
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Medidas.radioMd),
      side: BorderSide(
        color: elegido
            ? p.accentEdge
            : atenuado
            ? p.borderDefault
            : p.borderControl,
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: elegido,
      enabled: alTocar != null,
      label: etiqueta,
      excludeSemantics: true,
      onTap: alTocar,
      child: Opacity(
        opacity: atenuado ? 0.45 : 1,
        child: Material(
          color: elegido ? p.accentBase : p.bgSurfaceRaised,
          shape: forma,
          child: InkWell(onTap: alTocar, customBorder: forma, child: child),
        ),
      ),
    );
  }
}
