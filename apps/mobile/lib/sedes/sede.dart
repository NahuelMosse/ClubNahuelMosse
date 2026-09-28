/// Una sede activa, como la devuelve la API.
class Sede {
  const Sede({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.apertura,
    required this.cierre,
    required this.dias,
    required this.canchas,
  });

  final int id;
  final String nombre;
  final String direccion;

  /// `HH:MM`; un cierre a las `00:00` es la medianoche.
  final String apertura;
  final String cierre;

  /// Días de la semana en que abre, de 1 (lunes) a 7 (domingo).
  final List<int> dias;
  final int canchas;

  /// «Lunes a sábado», o los días sueltos si no son seguidos desde el lunes.
  String get diasLegibles => diasDeLaSemana(dias);

  static Sede? desdeJson(Object? json) {
    if (json case {
      'id': final int id,
      'nombre': final String nombre,
      'direccion': final String direccion,
      'apertura': final String apertura,
      'cierre': final String cierre,
      'dias': final List<Object?> dias,
      'canchas': final int canchas,
    }) {
      return Sede(
        id: id,
        nombre: nombre,
        direccion: direccion,
        apertura: apertura,
        cierre: cierre,
        dias: [...dias.whereType<int>()],
        canchas: canchas,
      );
    }
    return null;
  }
}

/// Las opciones de «DÍAS QUE ABRE» del alta de sede.
enum DiasQueAbre {
  lunesADomingo('Lunes a domingo', [1, 2, 3, 4, 5, 6, 7]),
  lunesASabado('Lunes a sábado', [1, 2, 3, 4, 5, 6]),
  lunesAViernes('Lunes a viernes', [1, 2, 3, 4, 5]);

  const DiasQueAbre(this.texto, this.dias);
  final String texto;
  final List<int> dias;
}

const _abreviados = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

String diasDeLaSemana(List<int> dias) {
  final ordenados = {...dias}.toList()..sort();
  for (final opcion in DiasQueAbre.values) {
    if (ordenados.length == opcion.dias.length &&
        ordenados.indexed.every((e) => e.$2 == opcion.dias[e.$1])) {
      return opcion.texto;
    }
  }
  return [
    for (final d in ordenados)
      if (d >= 1 && d <= 7) _abreviados[d - 1],
  ].join(', ');
}
