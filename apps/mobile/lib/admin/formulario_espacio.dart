import 'package:flutter/material.dart';

import '../comun/formato_precio.dart';
import '../comun/selector.dart';
import '../tema/tema.dart';
import '../tema/tokens.dart';

const obligatorio = 'Este campo es obligatorio';
const _precioMaximo = 9999999;

/// El error del [texto] del precio por hora: obligatorio y entre $ 1 y $ 9.999.999.
String? errorDePrecio(String texto) {
  final precio = leerPrecio(texto);
  if (precio == null) return obligatorio;
  return precio < 1 || precio > _precioMaximo
      ? 'Ingresá un precio entre \$ 1 y \$ 9.999.999'
      : null;
}

/// El título del formulario de un espacio, con la explicación de cómo se arma el nombre.
List<Widget> encabezadoDeEspacio(BuildContext context, String titulo) {
  final p = context.paleta;
  return [
    Semantics(
      header: true,
      child: Text(titulo, style: Textos.h1.copyWith(color: p.textPrimary)),
    ),
    const SizedBox(height: Medidas.s4),
    Text(
      'El nombre se arma solo con la sede, la dirección, el deporte, '
      'el tipo y el número.',
      style: Textos.cuerpo.copyWith(color: p.textSecondary),
    ),
    const SizedBox(height: Medidas.s16),
  ];
}

/// Pide elegir la condición (techada o al aire libre) o la iluminación del espacio; `null`
/// si se cerró sin elegir.
Future<bool?> elegirSiNo(
  BuildContext context, {
  required bool condicion,
  required bool? elegida,
}) => elegirOpcion<bool>(
  context,
  titulo: condicion ? 'Condición' : 'Iluminación',
  opciones: condicion
      ? const [(false, 'Al aire libre'), (true, 'Techada')]
      : const [(true, 'Iluminada'), (false, 'Sin iluminación')],
  elegida: elegida,
);
