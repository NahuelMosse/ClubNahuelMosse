/// A start hour of the grid, with its end according to the queried duration.
class Slot {
  const Slot({required this.start, required this.end, required this.available});

  /// `HH:MM` in club time.
  final String start;
  final String end;
  final bool available;

  /// «18:00 – 19:00».
  String get text => '$start – $end';
}
