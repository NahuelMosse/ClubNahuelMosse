import '../espacios/espacio.dart';
import 'sede.dart';

/// Los nombres de los deportes de la sede, en el orden del catálogo.
List<String> deportesDe(Sede sede, Catalogo catalogo) => [
  for (final d in catalogo.deportes)
    if (sede.deportes.contains(d.clave)) d.nombre,
];

String cantidadDeCanchas(int n) => n == 1 ? '1 cancha' : '$n canchas';
