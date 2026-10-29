// kit-shape: a screen or error family kept with its private parts.
import '../../../common/club_timezone.dart';
import '../../../common/dates.dart';
import 'notification_kind.dart';

/// A dónde lleva tocar un aviso: Mis reservas con la reserva resaltada. Las cancelaciones —del
/// club o de la propia persona— dejaron la reserva en el historial, así que abren esa pestaña.
String noticeRoute(NotificationKind? kind, String? bookingId) {
  final history =
      kind == NotificationKind.forcedCancellation ||
      kind == NotificationKind.userCancellation;
  final parameters = [
    if (history) 'historial=1',
    if (bookingId != null) 'reserva=$bookingId',
  ];
  return parameters.isEmpty ? '/reservas' : '/reservas?${parameters.join('&')}';
}

/// Una entrada del centro de notificaciones.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.bookingId,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final String? bookingId;

  /// En la hora del club.
  final DateTime createdAt;
  final bool read;

  AppNotification markedRead() => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    bookingId: bookingId,
    createdAt: createdAt,
    read: true,
  );

  static AppNotification? fromJson(Object? json) {
    if (json case {
      'id': final String id,
      'tipo': final String kind,
      'titulo': final String title,
      'cuerpo': final String body,
      'creada_en': final String createdAt,
      'leida': final bool read,
    }) {
      final parsedKind = NotificationKind.fromApi(kind);
      final when = DateTime.tryParse(createdAt);
      if (parsedKind == null || when == null) return null;
      return AppNotification(
        id: id,
        kind: parsedKind,
        title: title,
        body: body,
        bookingId: json['reserva_id'] is String
            ? json['reserva_id'] as String
            : null,
        createdAt: inClubTime(when),
        read: read,
      );
    }
    return null;
  }
}

/// Los días se cuentan en el club, sea cual sea la zona del teléfono.
DateTime inClubTime(DateTime moment) => toClubTime(moment);

/// Cuándo llegó un aviso, sin texto: la pantalla lo escribe en el idioma de la app.
enum ArrivalWhen { today, yesterday, date, now, minutesAgo, hoursAgo }

/// [amount] cuenta los minutos u horas de `minutesAgo` y `hoursAgo`; [date] (`dd/mm`) sólo
/// la lleva `date`.
typedef Arrival = ({ArrivalWhen when, int amount, String date});

/// Las notificaciones de un mismo día, con su rótulo: hoy, ayer o `dd/mm`.
class DayGroup {
  const DayGroup(this.arrival, this.notifications);
  final Arrival arrival;
  final List<AppNotification> notifications;
}

DateTime _day(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// Hoy, ayer o `dd/mm`, según [now] en la hora del club.
Arrival dayOf(DateTime createdAt, DateTime now) {
  final days = _day(now).difference(_day(createdAt)).inDays;
  return switch (days) {
    0 => (when: ArrivalWhen.today, amount: 0, date: ''),
    1 => (when: ArrivalWhen.yesterday, amount: 0, date: ''),
    _ => (when: ArrivalWhen.date, amount: 0, date: dayAndMonth(createdAt)),
  };
}

/// Cuándo llegó: ahora, hace 2 minutos, hace 3 horas, ayer o `dd/mm`.
Arrival arrivalOf(DateTime createdAt, DateTime now) {
  final elapsed = now.difference(createdAt);
  final day = dayOf(createdAt, now);
  if (day.when != ArrivalWhen.today) return day;
  if (elapsed.inMinutes < 1) {
    return (when: ArrivalWhen.now, amount: 0, date: '');
  }
  if (elapsed.inMinutes < 60) {
    return (when: ArrivalWhen.minutesAgo, amount: elapsed.inMinutes, date: '');
  }
  return (when: ArrivalWhen.hoursAgo, amount: elapsed.inHours, date: '');
}

/// Agrupa por día conservando el orden de [list], de la más nueva a la más vieja.
List<DayGroup> groupByDay(List<AppNotification> list, DateTime now) {
  final groups = <DayGroup>[];
  for (final n in list) {
    final day = dayOf(n.createdAt, now);
    if (groups.isNotEmpty && groups.last.arrival == day) {
      groups.last.notifications.add(n);
    } else {
      groups.add(DayGroup(day, [n]));
    }
  }
  return groups;
}
