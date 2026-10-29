import 'weekdays_label.dart';

export 'open_days.dart';
export 'weekdays_label.dart';

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
  WeekdaysLabel get daysLabel => weekdaysLabel(days);

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
