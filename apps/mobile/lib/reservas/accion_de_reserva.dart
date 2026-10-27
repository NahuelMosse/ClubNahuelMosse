import 'package:flutter/material.dart';

/// Un botón de la tarjeta, que dice de qué reserva es.
class AccionDeReserva extends StatelessWidget {
  const AccionDeReserva({
    super.key,
    required this.expandir,
    required this.etiqueta,
    required this.alTocar,
    required this.child,
  });

  final bool expandir;
  final String etiqueta;
  final VoidCallback? alTocar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final boton = Semantics(
      label: etiqueta,
      excludeSemantics: true,
      button: true,
      enabled: alTocar != null,
      onTap: alTocar,
      child: child,
    );
    return expandir ? Expanded(child: boton) : boton;
  }
}
