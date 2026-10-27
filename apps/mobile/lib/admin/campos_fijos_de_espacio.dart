import 'package:flutter/material.dart';

import '../espacios/espacio.dart';
import '../tema/tokens.dart';
import 'campo_de_solo_lectura.dart';

/// La sede, el deporte y el tipo de [espacio], que se ven pero no cambian; el deporte y el
/// tipo con su nombre si hay [catalogo], y si no con su clave.
List<Widget> camposFijosDeEspacio(Espacio espacio, Catalogo? catalogo) {
  final deporte = catalogo?.deporte(espacio.deporte)?.nombre ?? espacio.deporte;
  final tipo =
      catalogo?.tipoCorto(espacio.deporte, espacio.tipo) ?? espacio.tipo;
  return [
    CampoDeSoloLectura(
      etiqueta: 'SEDE',
      etiquetaAccesible: 'Sede',
      valor: espacio.sede,
    ),
    const SizedBox(height: Medidas.s12),
    CampoDeSoloLectura(
      etiqueta: 'DEPORTE',
      etiquetaAccesible: 'Deporte',
      valor: deporte,
    ),
    const SizedBox(height: Medidas.s12),
    CampoDeSoloLectura(
      etiqueta: 'TIPO',
      etiquetaAccesible: 'Tipo',
      valor: tipo,
    ),
    const SizedBox(height: Medidas.s12),
  ];
}
