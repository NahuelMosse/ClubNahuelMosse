import 'open_days.dart';

/// Los días que abre una sede: una de las [OpenDays] si son exactamente esos, o los
/// días sueltos (de 1 a 7) si no lo son. Dos sedes con los mismos días dan valores iguales.
class WeekdaysLabel {
  const WeekdaysLabel(this.option, this.days);

  final OpenDays? option;

  /// Los días sueltos, ordenados y sin repetir; vacío si hay [option].
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
