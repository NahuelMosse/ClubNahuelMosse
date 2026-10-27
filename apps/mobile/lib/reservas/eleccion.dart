import '../comun/fechas.dart';
import '../espacios/espacio.dart';
import '../sedes/sede.dart';

/// Lo que se eligió en los horarios y pasa a la confirmación de la reserva. Elegir no
/// reserva nada.
class Eleccion {
  const Eleccion({
    required this.sede,
    required this.cancha,
    required this.tipo,
    required this.fecha,
    required this.inicio,
    required this.fin,
    required this.horas,
  });

  final Sede sede;
  final Espacio cancha;

  /// El tipo como se muestra: «Fútbol 5».
  final String tipo;
  final DateTime fecha;

  /// `HH:MM` en la hora del club.
  final String inicio;
  final String fin;
  final int horas;

  int get total => cancha.precioPorHora * horas;

  /// «18:00 – 19:00 · 1 hora».
  String get horario => '$inicio – $fin · ${duracion(horas)}';
}
