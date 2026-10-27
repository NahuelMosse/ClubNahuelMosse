import 'package:flutter/material.dart';

import '../comun/campo_texto.dart';
import '../comun/formato_precio.dart';

/// El campo del precio por hora de un espacio.
class CampoDePrecioPorHora extends StatelessWidget {
  const CampoDePrecioPorHora({
    super.key,
    required this.controlador,
    required this.error,
    required this.habilitado,
  });

  final TextEditingController controlador;
  final String? error;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    return CampoTexto(
      etiqueta: 'PRECIO POR HORA',
      etiquetaAccesible: 'Precio por hora',
      controlador: controlador,
      placeholder: '\$ 0',
      error: error,
      habilitado: habilitado,
      teclado: TextInputType.number,
      accion: TextInputAction.done,
      formateadores: const [FormatoPrecio()],
    );
  }
}
