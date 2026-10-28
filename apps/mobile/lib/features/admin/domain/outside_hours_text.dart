// kit-boundary: uses the domain types of another feature directly; features export no public index yet.
import '../../../common/dates.dart';
import '../../venues/domain/venue.dart';
import 'venue_rules.dart';

/// «2 reservas futuras de Sede Morón empiezan antes de las 09:00…», depending on what
/// shrank in the venue [before] when changing it to [opensAt], [closesAt] and [openDays].
String bookingsOutsideHoursText(
  int count, {
  required Venue? before,
  required int opensAt,
  required int closesAt,
  required List<int> openDays,
}) {
  final single = count == 1;
  final subject =
      '$count ${single ? 'reserva futura' : 'reservas futuras'} de ${before?.name}';
  final closesHour = closesAt == 0 ? 24 : closesAt;
  final beforeOpensAt = before == null ? null : parseWholeHour(before.opening);
  final beforeClosesAt = switch (before == null
      ? null
      : parseWholeHour(before.closing)) {
    0 => 24,
    final c => c,
  };
  final reasons = [
    if (beforeOpensAt != null && opensAt > beforeOpensAt)
      '${single ? 'empieza' : 'empiezan'} antes de las ${wholeHour(opensAt)}',
    if (beforeClosesAt != null && closesHour < beforeClosesAt)
      '${single ? 'termina' : 'terminan'} después de las ${wholeHour(closesAt)}',
    if (before != null && before.days.any((d) => !openDays.contains(d)))
      '${single ? 'cae' : 'caen'} en un día que la sede deja de abrir',
  ];
  final reason = reasons.length == 1
      ? reasons.single
      : '${single ? 'queda' : 'quedan'} fuera del horario nuevo';
  return '$subject $reason. Si guardás, ${single ? 'se mantiene' : 'se mantienen'} '
      'en su horario original: el cambio rige para las reservas nuevas.';
}
