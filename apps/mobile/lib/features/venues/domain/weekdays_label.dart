import 'open_days.dart';

/// The days a venue opens: one of the [OpenDays] if they are exactly those, or the single
/// days (1 to 7) if not. Two venues with the same days give equal values.
class WeekdaysLabel {
  const WeekdaysLabel(this.option, this.days);

  final OpenDays? option;

  /// The single days, sorted and without repeats; empty if there is [option].
  final List<int> days;

  @override
  bool operator ==(Object other) =>
      other is WeekdaysLabel &&
      other.option == option &&
      other.days.join(',') == days.join(',');

  @override
  int get hashCode => Object.hash(option, days.join(','));
}

WeekdaysLabel weekdaysLabel(List<int> days) {
  final sorted = {...days}.toList()..sort();
  for (final option in OpenDays.values) {
    if (sorted.length == option.days.length &&
        sorted.indexed.every((e) => e.$2 == option.days[e.$1])) {
      return WeekdaysLabel(option, const []);
    }
  }
  return WeekdaysLabel(null, [
    for (final d in sorted)
      if (d >= 1 && d <= 7) d,
  ]);
}
