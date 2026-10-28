import '../../../common/dates.dart';

/// Una sede activa, como la devuelve la API.
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.address,
    required this.opening,
    required this.closing,
    required this.days,
    required this.spaceCount,
    this.sports = const [],
  });

  final String id;
  final String name;
  final String address;

  /// `HH:MM`; un cierre a las `00:00` es la medianoche.
  final String opening;
  final String closing;

  /// Días de la semana en que abre, de 1 (lunes) a 7 (domingo).
  final List<int> days;
  final int spaceCount;

  /// Las claves de los deportes de sus canchas (`Futbol`, `Tenis`), sin repetir.
  final List<String> sports;

  /// «Lunes a sábado», o los días sueltos si no son seguidos desde el lunes.
  String get daysLabel => weekdaysLabel(days);

  static Venue? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'nombre': final String name,
      'direccion': final String address,
      'apertura': final String opening,
      'cierre': final String closing,
      'dias': final List<Object?> days,
      'canchas': final int spaceCount,
    }) {
      return Venue(
        id: id,
        name: name,
        address: address,
        opening: opening,
        closing: closing,
        days: [...days.whereType<int>()],
        spaceCount: spaceCount,
        sports: switch (json['deportes']) {
          final List<Object?> items => [...items.whereType<String>()],
          _ => const [],
        },
      );
    }
    return null;
  }
}

/// Las opciones de «DÍAS QUE ABRE» del alta de sede.
enum OpenDays {
  mondayToSunday('Lunes a domingo', [1, 2, 3, 4, 5, 6, 7]),
  mondayToSaturday('Lunes a sábado', [1, 2, 3, 4, 5, 6]),
  mondayToFriday('Lunes a viernes', [1, 2, 3, 4, 5]);

  const OpenDays(this.text, this.days);
  final String text;
  final List<int> days;
}

String weekdaysLabel(List<int> days) {
  final sorted = {...days}.toList()..sort();
  for (final option in OpenDays.values) {
    if (sorted.length == option.days.length &&
        sorted.indexed.every((e) => e.$2 == option.days[e.$1])) {
      return option.text;
    }
  }
  return [
    for (final d in sorted)
      if (d >= 1 && d <= 7) shortWeekdayName(d),
  ].join(', ');
}
