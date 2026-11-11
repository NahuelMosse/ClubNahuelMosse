import 'weekdays_label.dart';

export 'open_days.dart';
export 'weekdays_label.dart';

/// An active venue, as the API returns it.
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

  /// `HH:MM`; a closing at `00:00` is midnight.
  final String opening;
  final String closing;

  /// Days of the week it opens, from 1 (Monday) to 7 (Sunday).
  final List<int> days;
  final int spaceCount;

  /// The keys of the sports of its courts (`Futbol`, `Tenis`), without repeats.
  final List<String> sports;

  /// «Lunes a sábado», or the single days if they are not consecutive from Monday.
  WeekdaysLabel get daysLabel => weekdaysLabel(days);

  static Venue? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'address': final String address,
      'opens_at': final String opening,
      'closes_at': final String closing,
      'open_days': final List<Object?> days,
      'space_count': final int spaceCount,
    }) {
      return Venue(
        id: id,
        name: name,
        address: address,
        opening: opening,
        closing: closing,
        days: [...days.whereType<int>()],
        spaceCount: spaceCount,
        sports: switch (json['sports']) {
          final List<Object?> items => [...items.whereType<String>()],
          _ => const [],
        },
      );
    }
    return null;
  }
}
