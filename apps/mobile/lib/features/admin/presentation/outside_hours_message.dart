import '../../../l10n/app_localizations.dart';
import '../domain/outside_hours.dart';

/// «2 reservas futuras de Sede Morón empiezan antes de las 09:00…»: what saving the new
/// schedule leaves outside it, agreeing with the number of bookings.
String outsideHoursMessage(AppLocalizations l10n, OutsideHours hours) {
  final count = hours.count;
  final reason = switch (hours.reasons) {
    [OutsideReason.startsBefore] => l10n.adminOutsideStartsBefore(
      count,
      hours.opensHour,
    ),
    [OutsideReason.endsAfter] => l10n.adminOutsideEndsAfter(
      count,
      hours.closesHour,
    ),
    [OutsideReason.closedDay] => l10n.adminOutsideClosedDay(count),
    _ => l10n.adminOutsideNewSchedule(count),
  };
  return l10n.adminOutsideNotice(
    l10n.adminOutsideSubject(count, '${hours.venueName}'),
    reason,
    l10n.adminOutsideKeeps(count),
  );
}
